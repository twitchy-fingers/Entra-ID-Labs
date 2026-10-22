<#
.SYNOPSIS
    Revokes refresh tokens and session cookies for one or more users.

.DESCRIPTION
    Standalone use cases: suspected account compromise, lost device, or forcing a fresh
    token after an access change. Leaver and mover call the same Graph action internally.

    Revocation invalidates refresh tokens and browser session cookies. Access tokens already
    issued remain valid until they expire (typically 60–90 minutes) unless the application
    supports Continuous Access Evaluation (CAE).

.EXAMPLE
    ./revoke-sessions.ps1 -UserPrincipalName jcruz@danotech.onmicrosoft.com -Reason "Lost laptop, ticket SEC-118"

.EXAMPLE
    'kadeyemi@danotech.onmicrosoft.com','jchen@danotech.onmicrosoft.com' |
        ./revoke-sessions.ps1 -Reason "Role change"
#>
#Requires -Version 7.0
#Requires -Modules Microsoft.Graph.Authentication
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, ValueFromPipeline)][string[]]$UserPrincipalName,
    [Parameter(Mandatory)][string]$Reason
)

begin {
    $ErrorActionPreference = 'Stop'
    Import-Module (Join-Path $PSScriptRoot 'JmlCommon.psm1') -Force
    $config = Get-JmlConfig
    Connect-JmlGraph -TenantDomain $config.tenantDomain -Scopes @('User.Read.All', 'User.RevokeSessions.All')
}

process {
    foreach ($upn in $UserPrincipalName) {
        try {
            $user = Get-MgUser -UserId $upn -Property Id, UserPrincipalName
        }
        catch {
            Write-JmlLog -Process RevokeSessions -Target $upn -Action 'Lookup user' -Result Error -Detail 'User not found'
            continue
        }
        if ($PSCmdlet.ShouldProcess($upn, 'Revoke sign-in sessions')) {
            Revoke-MgUserSignInSession -UserId $user.Id | Out-Null
            Write-JmlLog -Process RevokeSessions -Target $upn -Action 'Revoke sessions' -Detail $Reason
        }
        else {
            Write-JmlLog -Process RevokeSessions -Target $upn -Action 'Revoke sessions' -Result WhatIf -Detail $Reason
        }
    }
}
