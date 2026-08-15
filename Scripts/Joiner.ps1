# Provision-EntraNewHires.ps1
# Bulk-creates Entra ID users from EntraID_NewHires_WithDept.csv and assigns
# them to their department's role-based group.
#
# Prerequisites:
#   Install-Module Microsoft.Graph -Scope CurrentUser
#   Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All"

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups

Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All"

$users = Import-Csv "C:\IAM-Lab\EntraID_NewHires_WithDept.csv" | Where-Object { $_.Status -eq "Active" }

foreach ($u in $users) {

    # CSV provides a combined DisplayName ("First Last") rather than separate fields,
    # so split it out for GivenName/Surname
    $nameParts = $u.DisplayName -split " ", 2
    $firstName = $nameParts[0]
    $lastName  = if ($nameParts.Count -gt 1) { $nameParts[1] } else { "" }

    # UserPrincipalName already includes the full domain in the CSV, so use it as-is
    $upn = $u.UserPrincipalName
    # MailNickname is the part before the @ symbol
    $mailNickname = ($upn -split "@")[0]

    # Skip if the account already exists (safe to re-run)
    if (Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue) {
        Write-Host "Skipping $upn - account already exists" -ForegroundColor Yellow
        continue
    }

    $passwordProfile = @{
        Password                      = $u.DefaultPassword
        ForceChangePasswordNextSignIn = $true
    }

    try {
        $newUser = New-MgUser -DisplayName $u.DisplayName `
            -GivenName $firstName -Surname $lastName `
            -UserPrincipalName $upn `
            -MailNickname $mailNickname `
            -AccountEnabled `
            -PasswordProfile $passwordProfile `
            -Department $u.Department `
            -JobTitle $u.JobTitle `
            -UsageLocation "US"

        Write-Host "Created user: $upn" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create $upn : $_" -ForegroundColor Red
        continue
    }

    # Assign to the correct role-based group
    $group = Get-MgGroup -Filter "displayName eq 'SG-$($u.Department)-Users'" -ErrorAction SilentlyContinue

    if (-not $group) {
        Write-Host "Group SG-$($u.Department)-Users not found - skipping group assignment for $upn" -ForegroundColor Red
        continue
    }

    try {
        New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $newUser.Id
        Write-Output "Provisioned $upn into SG-$($u.Department)-Users"
    }
    catch {
        Write-Host "Failed to add $upn to SG-$($u.Department)-Users : $_" -ForegroundColor Red
    }
}

