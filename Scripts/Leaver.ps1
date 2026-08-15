# EntraID_Leaver.ps1
# Fully deprovisions a departing user in Entra ID: disables sign-in, strips group
# memberships, revokes active sessions, and removes licenses.
#
# Prerequisites:
#   Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All"

function Disable-EntraLeaver {
    param($Username)

    $upn = "$Username@danotech.onmicrosoft.com"
    $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -Property Id, DisplayName

    if (-not $user) {
        Write-Host "No user found for UPN: $upn" -ForegroundColor Red
        return
    }

    # Disable sign-in
    Update-MgUser -UserId $user.Id -AccountEnabled:$false

    # Remove all group memberships
    $memberships = Get-MgUserMemberOf -UserId $user.Id
    foreach ($group in $memberships) {
        Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $user.Id -ErrorAction SilentlyContinue
    }

    # Revoke all active sessions/tokens — this is the step that actually kills a live session,
    # separate from disabling future sign-ins
    Revoke-MgUserSignInSession -UserId $user.Id

    # Remove assigned licenses
    $licenseDetails = Get-MgUserLicenseDetail -UserId $user.Id
    foreach ($lic in $licenseDetails) {
        Set-MgUserLicense -UserId $user.Id -AddLicenses @() -RemoveLicenses @($lic.SkuId)
    }

    Write-Output "$Username fully deprovisioned at $(Get-Date)"
}

Disable-EntraLeaver -Username "tthomas"
