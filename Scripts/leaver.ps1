<#
.SYNOPSIS
    Leaver process: removes all access for a departing user while preserving the account for the retention period.

.DESCRIPTION
    0. Captures an evidence snapshot of all access (groups, app roles, PIM, directory roles, licenses)
    1. Disables the account (blocks new sign-ins)
    2. Revokes refresh tokens and session cookies
    3. Removes PIM eligible role assignments
    4. Reports any active directory role assignments for manual review
    5. Removes membership of every assigned group (dynamic groups drop out automatically)
    6. Removes direct app role assignments
    7. Reclaims directly assigned licenses (unless -KeepLicense)

    The account is NOT deleted. Deletion happens after the retention period in SOP-JML-03.

.EXAMPLE
    ./leaver.ps1 -UserPrincipalName jchen@danotech.onmicrosoft.com -TerminationType Voluntary -TicketNumber HR-2041 -WhatIf
#>
#Requires -Version 7.0
#Requires -Modules Microsoft.Graph.Authentication
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$UserPrincipalName,
    [Parameter(Mandatory)][ValidateSet('Voluntary', 'Involuntary')][string]$TerminationType,
    [string]$TicketNumber = 'not-recorded',
    [switch]$KeepLicense
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'JmlCommon.psm1') -Force

$config = Get-JmlConfig
Connect-JmlGraph -TenantDomain $config.tenantDomain -Scopes @(
    'User.ReadWrite.All',
    'Group.ReadWrite.All',
    'AppRoleAssignment.ReadWrite.All',
    'RoleManagement.Read.Directory',
    'RoleEligibilitySchedule.ReadWrite.Directory'
)

$user = Get-MgUser -UserId $UserPrincipalName -Property Id, UserPrincipalName, DisplayName, AccountEnabled, `
    EmployeeId, Department, JobTitle, AssignedLicenses, LicenseAssignmentStates
$upn = $user.UserPrincipalName
$justification = "Leaver ($TerminationType), ticket $TicketNumber"

# --- 0. Evidence snapshot ---------------------------------------------------
$groups      = @(Get-MgUserMemberOfAsGroup -UserId $user.Id -All -Property Id, DisplayName, GroupTypes)
$appRoles    = @(Get-MgUserAppRoleAssignment -UserId $user.Id -All)
$eligibility = @(Get-JmlPimEligibility -UserId $user.Id)
$activeRoles = @(Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$($user.Id)'" -All)
$directLicenses = @($user.LicenseAssignmentStates | Where-Object { -not $_.AssignedByGroup })

$snapshot = [ordered]@{
    CapturedUtc        = (Get-Date).ToUniversalTime().ToString('o')
    UserPrincipalName  = $upn
    EmployeeId         = $user.EmployeeId
    TerminationType    = $TerminationType
    TicketNumber       = $TicketNumber
    Groups             = $groups | ForEach-Object { [ordered]@{ Name = $_.DisplayName; Dynamic = ($_.GroupTypes -contains 'DynamicMembership') } }
    AppRoleAssignments = $appRoles | ForEach-Object { [ordered]@{ Resource = $_.ResourceDisplayName; AppRoleId = $_.AppRoleId } }
    PimEligibleRoles   = $eligibility.RoleName
    ActiveDirectoryRoleAssignmentIds = $activeRoles.RoleDefinitionId
    DirectLicenseSkuIds = $directLicenses.SkuId
}
$logDir = Get-JmlLogDirectory
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -WhatIf:$false | Out-Null }
$snapshotPath = Join-Path $logDir ("leaver-snapshot-{0}-{1}.json" -f $user.EmployeeId, (Get-Date -Format 'yyyyMMdd-HHmmss'))
$snapshot | ConvertTo-Json -Depth 5 | Set-Content -Path $snapshotPath -WhatIf:$false
Write-JmlLog -Process Leaver -Target $upn -Action 'Evidence snapshot' -Detail $snapshotPath

# --- 1. Disable account -----------------------------------------------------
if ($PSCmdlet.ShouldProcess($upn, 'Disable account')) {
    Update-MgUser -UserId $user.Id -AccountEnabled:$false
    Write-JmlLog -Process Leaver -Target $upn -Action 'Disable account' -Detail $justification
}

# --- 2. Revoke sessions -----------------------------------------------------
if ($PSCmdlet.ShouldProcess($upn, 'Revoke sign-in sessions')) {
    Revoke-MgUserSignInSession -UserId $user.Id | Out-Null
    Write-JmlLog -Process Leaver -Target $upn -Action 'Revoke sessions'
}

# --- 3. PIM eligibility -----------------------------------------------------
foreach ($elig in $eligibility) {
    if ($PSCmdlet.ShouldProcess($upn, "Remove PIM eligibility: $($elig.RoleName)")) {
        Remove-JmlPimEligibility -UserId $user.Id -RoleDefinitionId $elig.RoleDefinitionId `
            -DirectoryScopeId $elig.DirectoryScopeId -Justification $justification
        Write-JmlLog -Process Leaver -Target $upn -Action 'Remove PIM eligibility' -Detail $elig.RoleName
    }
}

# --- 4. Active directory role assignments (manual review) -------------------
foreach ($assignment in $activeRoles) {
    $roleName = (Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $assignment.RoleDefinitionId).DisplayName
    Write-JmlLog -Process Leaver -Target $upn -Action 'Active directory role found' -Result Warning `
        -Detail "$roleName — standing or activated assignment; remove manually in PIM and record in the ticket"
}

# --- 5. Group memberships ---------------------------------------------------
foreach ($group in $groups) {
    if ($group.GroupTypes -contains 'DynamicMembership') {
        Write-JmlLog -Process Leaver -Target $upn -Action "Group $($group.DisplayName)" -Result Skipped `
            -Detail 'Dynamic group: membership drops automatically once the account is disabled'
        continue
    }
    if ($PSCmdlet.ShouldProcess($upn, "Remove from $($group.DisplayName)")) {
        try {
            Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $user.Id
            Write-JmlLog -Process Leaver -Target $upn -Action "Remove group $($group.DisplayName)"
        }
        catch {
            Write-JmlLog -Process Leaver -Target $upn -Action "Remove group $($group.DisplayName)" -Result Error -Detail $_.Exception.Message
        }
    }
}

# --- 6. Direct app role assignments -----------------------------------------
foreach ($assignment in $appRoles) {
    if ($PSCmdlet.ShouldProcess($upn, "Remove app role assignment on $($assignment.ResourceDisplayName)")) {
        Remove-MgUserAppRoleAssignment -UserId $user.Id -AppRoleAssignmentId $assignment.Id
        Write-JmlLog -Process Leaver -Target $upn -Action 'Remove direct app role assignment' -Detail $assignment.ResourceDisplayName
    }
}

# --- 7. Licenses ------------------------------------------------------------
if (-not $KeepLicense -and $directLicenses.Count -gt 0) {
    if ($PSCmdlet.ShouldProcess($upn, 'Remove directly assigned licenses')) {
        Set-MgUserLicense -UserId $user.Id -AddLicenses @() -RemoveLicenses @($directLicenses.SkuId) | Out-Null
        Write-JmlLog -Process Leaver -Target $upn -Action 'Reclaim licenses' -Detail (@($directLicenses.SkuId) -join ',')
    }
}

Write-JmlLog -Process Leaver -Target $upn -Action 'Leaver complete' -Detail "Account retained (disabled). Delete after retention period per SOP-JML-03."
