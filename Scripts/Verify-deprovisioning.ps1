# Confirm account is disabled
Get-MgUser -Filter "userPrincipalName eq 'tthomas@danotech.onmicrosoft.com'" -Property AccountEnabled

# Confirm no remaining group memberships
$user = Get-MgUser -Filter "userPrincipalName eq 'tthomas@danotech.onmicrosoft.com'"
Get-MgUserMemberOf -UserId $user.Id

# Confirm no active licenses
Get-MgUserLicenseDetail -UserId $user.Id
