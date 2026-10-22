<#
.SYNOPSIS
    Mover process: changes a user's role, removing old access before granting new access.

.DESCRIPTION
    1. Records the user's current role groups and attributes (before state)
    2. Removes the user from every RBAC role group that doesn't match the new role
    3. Removes PIM eligibility if the new role is not privileged
    4. Adds the user to the new role group (or flags a PIM request if privileged)
    5. Updates department, job title, and manager if supplied
    6. Optionally revokes sessions so the next token reflects the new role claims

    Removing before adding prevents access accumulation (privilege creep) across role changes.

.EXAMPLE
    ./mover.ps1 -UserPrincipalName kadeyemi@danotech.onmicrosoft.com -NewRole SalesManager `
        -NewJobTitle "Sales Manager" -RevokeSessions -WhatIf
#>
#Requires -Version 7.0
#Requires -Modules Microsoft.Graph.Authentication
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$UserPrincipalName,
    [Parameter(Mandatory)][string]$NewRole,
    [string]$NewDepartment,
    [string]$NewJobTitle,
    [string]$NewManagerUserPrincipalName,
    [switch]$RevokeSessions
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'JmlCommon.psm1') -Force

$config = Get-JmlConfig
if (-not $config.roles.ContainsKey($NewRole)) {
    throw "Role '$NewRole' is not in the approved catalog. Valid roles: $($config.roles.Keys -join ', ')"
}
$newRoleConfig = $config.roles[$NewRole]

Connect-JmlGraph -TenantDomain $config.tenantDomain -Scopes @(
    'User.ReadWrite.All',
    'Group.ReadWrite.All',
    'RoleManagement.Read.Directory',
    'RoleEligibilitySchedule.ReadWrite.Directory'
)

$user = Get-MgUser -UserId $UserPrincipalName -Property Id, UserPrincipalName, Department, JobTitle, AccountEnabled, EmployeeId
if (-not $user.AccountEnabled) { throw "$UserPrincipalName is disabled. The mover process applies to active employees only." }
$upn = $user.UserPrincipalName

# --- 1. Before state --------------------------------------------------------
$roleGroupNames    = Get-JmlRoleGroupNames -Config $config
$currentRoleGroups = @(Get-MgUserMemberOfAsGroup -UserId $user.Id -All -Property Id, DisplayName |
    Where-Object { $_.DisplayName -in $roleGroupNames })
$before = "Dept=$($user.Department); Title=$($user.JobTitle); RoleGroups=$(@($currentRoleGroups.DisplayName) -join ',')"
Write-JmlLog -Process Mover -Target $upn -Action 'Before state' -Detail $before

# --- 2. Remove old role groups first ----------------------------------------
foreach ($group in $currentRoleGroups) {
    if ($group.DisplayName -eq $newRoleConfig.roleGroup) { continue }
    if ($PSCmdlet.ShouldProcess($upn, "Remove from $($group.DisplayName)")) {
        Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $user.Id
        Write-JmlLog -Process Mover -Target $upn -Action "Remove role group $($group.DisplayName)"
    }
    else {
        Write-JmlLog -Process Mover -Target $upn -Action "Remove role group $($group.DisplayName)" -Result WhatIf
    }
}

# --- 3. PIM eligibility -----------------------------------------------------
if (-not $newRoleConfig.privileged) {
    foreach ($elig in @(Get-JmlPimEligibility -UserId $user.Id)) {
        if ($PSCmdlet.ShouldProcess($upn, "Remove PIM eligibility: $($elig.RoleName)")) {
            Remove-JmlPimEligibility -UserId $user.Id -RoleDefinitionId $elig.RoleDefinitionId `
                -DirectoryScopeId $elig.DirectoryScopeId -Justification "Mover: role changed to $NewRole"
            Write-JmlLog -Process Mover -Target $upn -Action 'Remove PIM eligibility' -Detail $elig.RoleName
        }
    }
}

# --- 4. Grant new role access -----------------------------------------------
if ($newRoleConfig.privileged) {
    Write-JmlLog -Process Mover -Target $upn -Action 'Privileged access' -Result Warning `
        -Detail "New role '$NewRole' is privileged. No access granted. Submit a PIM eligibility request per SOP-JML-02."
}
elseif ($newRoleConfig.roleGroup) {
    $group = Get-JmlGroupByName -DisplayName $newRoleConfig.roleGroup
    if (-not $group) { throw "Role group '$($newRoleConfig.roleGroup)' does not exist. Create it (Phase 3) before running mover." }
    if ($PSCmdlet.ShouldProcess($upn, "Add to $($group.DisplayName)")) {
        $outcome = Add-JmlGroupMember -GroupId $group.Id -UserId $user.Id
        $result  = if ($outcome -eq 'AlreadyMember') { 'Skipped' } else { 'Success' }
        Write-JmlLog -Process Mover -Target $upn -Action "Add role group $($group.DisplayName)" -Result $result -Detail $outcome
    }
}
else {
    Write-JmlLog -Process Mover -Target $upn -Action 'Baseline access' -Result Skipped -Detail 'Baseline only (dynamic group)'
}

# --- 5. Attributes and manager ----------------------------------------------
$update = @{}
if ($NewDepartment) { $update.Department = $NewDepartment }
if ($NewJobTitle)   { $update.JobTitle   = $NewJobTitle }
if ($update.Count -gt 0 -and $PSCmdlet.ShouldProcess($upn, "Update attributes: $($update.Keys -join ', ')")) {
    Update-MgUser -UserId $user.Id @update
    Write-JmlLog -Process Mover -Target $upn -Action 'Update attributes' -Detail (($update.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; ')
}

if ($NewManagerUserPrincipalName) {
    $manager = Get-MgUser -UserId $NewManagerUserPrincipalName -Property Id, UserPrincipalName
    if ($PSCmdlet.ShouldProcess($upn, "Set manager to $($manager.UserPrincipalName)")) {
        Set-MgUserManagerByRef -UserId $user.Id -BodyParameter @{ '@odata.id' = "https://graph.microsoft.com/v1.0/users/$($manager.Id)" }
        Write-JmlLog -Process Mover -Target $upn -Action 'Set manager' -Detail $manager.UserPrincipalName
    }
}

# --- 6. Force fresh tokens --------------------------------------------------
if ($RevokeSessions -and $PSCmdlet.ShouldProcess($upn, 'Revoke sign-in sessions')) {
    Revoke-MgUserSignInSession -UserId $user.Id | Out-Null
    Write-JmlLog -Process Mover -Target $upn -Action 'Revoke sessions' -Detail 'Next sign-in issues tokens with the new role claims'
}

$afterGroups = @(Get-MgUserMemberOfAsGroup -UserId $user.Id -All -Property DisplayName |
    Where-Object { $_.DisplayName -in $roleGroupNames }).DisplayName -join ','
Write-JmlLog -Process Mover -Target $upn -Action 'After state' -Detail "Role=$NewRole; RoleGroups=$afterGroups"
