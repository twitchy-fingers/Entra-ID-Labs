<#
.SYNOPSIS
    Joiner process: provisions new hires in Microsoft Entra ID from the HR feed.

.DESCRIPTION
    Pass 1, for each row in the HR feed:
      1. Validates the Role against the approved role catalog (config/jml-config.json)
      2. Creates the user, or skips creation if the EmployeeId already exists (idempotent)
      3. Assigns the configured license (optional)
      4. Adds the user to their RBAC role group (access is never granted directly)
      5. Flags privileged roles for a separate PIM eligibility request (never auto-granted)
    Pass 2 sets manager relationships, so managers can appear anywhere in the file.

    Temporary passwords are displayed once at the end and are never written to disk.

.PARAMETER CsvPath
    Path to the HR feed CSV.

.EXAMPLE
    ./joiner.ps1 -CsvPath ../data/sample-hr-feed.csv -WhatIf

.EXAMPLE
    ./joiner.ps1 -CsvPath ../data/sample-hr-feed.csv
#>
#Requires -Version 7.0
#Requires -Modules Microsoft.Graph.Authentication
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'JmlCommon.psm1') -Force

$config = Get-JmlConfig
Connect-JmlGraph -TenantDomain $config.tenantDomain -Scopes @(
    'User.ReadWrite.All',
    'User-LifeCycleInfo.ReadWrite.All',
    'Group.ReadWrite.All',
    'Organization.Read.All'
)

# --- Validate the feed ------------------------------------------------------
$requiredColumns = 'EmployeeId','FirstName','LastName','Department','JobTitle','Role','ManagerEmployeeId','StartDate','UsageLocation'
$rows = @(Import-Csv -Path $CsvPath)
if ($rows.Count -eq 0) { throw "HR feed '$CsvPath' contains no rows." }
$missingColumns = $requiredColumns | Where-Object { $_ -notin $rows[0].PSObject.Properties.Name }
if ($missingColumns) { throw "HR feed is missing required columns: $($missingColumns -join ', ')" }

# --- Resolve license SKU (optional) -----------------------------------------
$skuId = $null
$seatsLeft = 0
if ($config.licenseSkuPartNumber) {
    $sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq $config.licenseSkuPartNumber
    if ($sku) {
        $skuId     = $sku.SkuId
        $seatsLeft = $sku.PrepaidUnits.Enabled - $sku.ConsumedUnits
        Write-Host "License $($config.licenseSkuPartNumber): $seatsLeft seat(s) available"
    }
    else { Write-Warning "License SKU '$($config.licenseSkuPartNumber)' not found. Users will be created without a license." }
}
$upnFormat = if ($config.upnFormat) { $config.upnFormat } else { 'firstInitialLastName' }

$usersByEmployeeId = @{}
$groupCache        = @{}
$tempCredentials   = [System.Collections.Generic.List[object]]::new()

# --- Pass 1: create users and grant role-group membership --------------------
foreach ($row in $rows) {
    $employeeId = $row.EmployeeId.Trim()
    $role       = $row.Role.Trim()

    if (-not $config.roles.ContainsKey($role)) {
        Write-JmlLog -Process Joiner -Target $employeeId -Action 'Validate role' -Result Error `
            -Detail "Role '$role' is not in the approved catalog. No account created; return to HR."
        continue
    }
    $roleConfig = $config.roles[$role]

    $user = Get-JmlUserByEmployeeId -EmployeeId $employeeId
    if ($user) {
        Write-JmlLog -Process Joiner -Target $user.UserPrincipalName -Action 'Create user' -Result Skipped `
            -Detail "EmployeeId $employeeId already exists"
    }
    else {
        $upn = Get-JmlUniqueUpn -FirstName $row.FirstName -LastName $row.LastName -Domain $config.tenantDomain -Format $upnFormat
        if (-not $PSCmdlet.ShouldProcess($upn, "Create user (Role=$role)")) {
            Write-JmlLog -Process Joiner -Target $upn -Action 'Create user' -Result WhatIf -Detail "Role=$role; Dept=$($row.Department)"
            continue
        }

        $password = New-JmlTempPassword
        $newUser = @{
            AccountEnabled    = $true
            DisplayName       = "$($row.FirstName.Trim()) $($row.LastName.Trim())"
            GivenName         = $row.FirstName.Trim()
            Surname           = $row.LastName.Trim()
            MailNickname      = $upn.Split('@')[0]
            UserPrincipalName = $upn
            Department        = $row.Department.Trim()
            JobTitle          = $row.JobTitle.Trim()
            EmployeeId        = $employeeId
            UsageLocation     = $row.UsageLocation.Trim()
            PasswordProfile   = @{ Password = $password; ForceChangePasswordNextSignIn = $true }
        }
        if ($row.StartDate) {
            $newUser.EmployeeHireDate = [datetime]::ParseExact($row.StartDate.Trim(), 'yyyy-MM-dd', [cultureinfo]::InvariantCulture)
        }

        $user = New-MgUser @newUser
        $tempCredentials.Add([PSCustomObject]@{ UserPrincipalName = $upn; TemporaryPassword = $password })
        Write-JmlLog -Process Joiner -Target $upn -Action 'Create user' -Detail "EmployeeId=$employeeId; Role=$role; Dept=$($row.Department)"

        if ($skuId -and $seatsLeft -gt 0) {
            try {
                Invoke-JmlWithRetry { Set-MgUserLicense -UserId $user.Id -AddLicenses @(@{ SkuId = $skuId }) -RemoveLicenses @() | Out-Null }
                $seatsLeft--
                Write-JmlLog -Process Joiner -Target $upn -Action 'Assign license' -Detail $config.licenseSkuPartNumber
            }
            catch {
                Write-JmlLog -Process Joiner -Target $upn -Action 'Assign license' -Result Warning -Detail $_.Exception.Message
            }
        }
        elseif ($skuId) {
            Write-JmlLog -Process Joiner -Target $upn -Action 'Assign license' -Result Warning `
                -Detail "No $($config.licenseSkuPartNumber) seats left. Account created unlicensed."
        }
    }
    $usersByEmployeeId[$employeeId] = $user

    # --- Role-based access: role group only, never direct assignment --------
    if ($roleConfig.privileged) {
        Write-JmlLog -Process Joiner -Target $user.UserPrincipalName -Action 'Privileged access' -Result Warning `
            -Detail "Role '$role' is privileged. No access granted. Submit a PIM eligibility request per SOP-JML-01 §6.5."
    }
    elseif (-not $roleConfig.roleGroup) {
        Write-JmlLog -Process Joiner -Target $user.UserPrincipalName -Action 'Baseline access' -Result Skipped `
            -Detail 'No role group; baseline access comes from dynamic group RBAC-StandardEmployee'
    }
    else {
        $groupName = $roleConfig.roleGroup
        if (-not $groupCache.ContainsKey($groupName)) { $groupCache[$groupName] = Get-JmlGroupByName -DisplayName $groupName }
        $group = $groupCache[$groupName]

        if (-not $group) {
            Write-JmlLog -Process Joiner -Target $user.UserPrincipalName -Action 'Add role group' -Result Warning `
                -Detail "Group '$groupName' does not exist yet (created in Phase 3). Re-run joiner afterwards."
        }
        elseif ($PSCmdlet.ShouldProcess($user.UserPrincipalName, "Add to $groupName")) {
            $outcome = Invoke-JmlWithRetry { Add-JmlGroupMember -GroupId $group.Id -UserId $user.Id }
            $result  = if ($outcome -eq 'AlreadyMember') { 'Skipped' } else { 'Success' }
            Write-JmlLog -Process Joiner -Target $user.UserPrincipalName -Action "Add role group $groupName" -Result $result -Detail $outcome
        }
    }
}

# --- Pass 2: manager relationships ------------------------------------------
foreach ($row in $rows) {
    $managerEmployeeId = "$($row.ManagerEmployeeId)".Trim()
    if (-not $managerEmployeeId) { continue }

    $user = $usersByEmployeeId[$row.EmployeeId.Trim()]
    if (-not $user) { continue }

    $manager = $usersByEmployeeId[$managerEmployeeId]
    if (-not $manager) { $manager = Get-JmlUserByEmployeeId -EmployeeId $managerEmployeeId }
    if (-not $manager) {
        Write-JmlLog -Process Joiner -Target $user.UserPrincipalName -Action 'Set manager' -Result Warning `
            -Detail "Manager EmployeeId $managerEmployeeId not found"
        continue
    }

    if ($PSCmdlet.ShouldProcess($user.UserPrincipalName, "Set manager to $($manager.UserPrincipalName)")) {
        Invoke-JmlWithRetry {
            Set-MgUserManagerByRef -UserId $user.Id -BodyParameter @{
                '@odata.id' = "https://graph.microsoft.com/v1.0/users/$($manager.Id)"
            }
        }
        Write-JmlLog -Process Joiner -Target $user.UserPrincipalName -Action 'Set manager' -Detail $manager.UserPrincipalName
    }
}

# --- Output temporary credentials once --------------------------------------
if ($tempCredentials.Count -gt 0) {
    Write-Host "`nTemporary passwords (shown once, never logged). Deliver securely; users must change them at first sign-in." -ForegroundColor Yellow
    $tempCredentials | Format-Table -AutoSize
}
Write-Host "Run log: $(Join-Path (Get-JmlLogDirectory) ("jml-{0}.csv" -f (Get-Date -Format 'yyyy-MM-dd')))"
