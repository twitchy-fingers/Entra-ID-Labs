# Create-EntraID_Groups.ps1
# Creates the department base groups and IT-Admins privileged group in Entra ID.
#
# Prerequisites:
#   Install-Module Microsoft.Graph -Scope CurrentUser
#   Connect-MgGraph -Scopes "Group.ReadWrite.All"

Import-Module Microsoft.Graph.Groups

Connect-MgGraph -Scopes "Group.ReadWrite.All"

$departments = @("Sales", "Engineering", "Finance", "IT", "HR")

foreach ($dept in $departments) {
    $groupName = "SG-$dept-Users"

    if (Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue) {
        Write-Host "Group already exists, skipping: $groupName" -ForegroundColor Yellow
        continue
    }

    try {
        New-MgGroup -DisplayName $groupName `
            -MailEnabled:$false `
            -MailNickname $groupName `
            -SecurityEnabled:$true `
            -Description "Role-based access group for $dept department" | Out-Null

        Write-Host "Created group: $groupName" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create $groupName : $_" -ForegroundColor Red
    }
}

# Privileged group, separated per least-privilege design
$adminGroup = "SG-IT-Admins"

if (Get-MgGroup -Filter "displayName eq '$adminGroup'" -ErrorAction SilentlyContinue) {
    Write-Host "Group already exists, skipping: $adminGroup" -ForegroundColor Yellow
}
else {
    try {
        New-MgGroup -DisplayName $adminGroup `
            -MailEnabled:$false `
            -MailNickname $adminGroup `
            -SecurityEnabled:$true `
            -Description "Privileged access group for IT administrators" | Out-Null

        Write-Host "Created group: $adminGroup" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create $adminGroup : $_" -ForegroundColor Red
    }
}
