# EntraID_Mover.ps1.ps1
# Moves an Entra ID user between department groups, updates their Department and
# Title attributes, and updates group membership. Title changes here can trigger
# dynamic group membership rules (e.g. a dynamic rule matching jobTitle eq
# "IT Administrator") in addition to any static group changes made explicitly below.

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups

Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All"

function Move-EntraEmployee {
    param($Username, $OldDept, $NewDept, $NewTitle)

    $upn = "$Username@danotech.onmicrosoft.com"
    $user = Get-MgUser -Filter "userPrincipalName eq '$upn'"

    if (-not $user) {
        Write-Host "User not found: $upn" -ForegroundColor Red
        return
    }

    $oldGroup = Get-MgGroup -Filter "displayName eq 'SG-$OldDept-Users'"
    $newGroup = Get-MgGroup -Filter "displayName eq 'SG-$NewDept-Users'"

    # Remove old access first
    if ($oldGroup) {
        Remove-MgGroupMemberByRef -GroupId $oldGroup.Id -DirectoryObjectId $user.Id
        Write-Host "Removed $Username from SG-$OldDept-Users" -ForegroundColor Green
    } else {
        Write-Host "Old group not found: SG-$OldDept-Users" -ForegroundColor Yellow
    }

    # Add new access
    if ($newGroup) {
        New-MgGroupMember -GroupId $newGroup.Id -DirectoryObjectId $user.Id
        Write-Host "Added $Username to SG-$NewDept-Users" -ForegroundColor Green
    } else {
        Write-Host "New group not found: SG-$NewDept-Users" -ForegroundColor Red
    }

    # Update Department and JobTitle attributes
    # (JobTitle change is what drives dynamic group membership rules automatically)
    Update-MgUser -UserId $user.Id -Department $NewDept -JobTitle $NewTitle

    Write-Output "$Username moved from $OldDept to $NewDept, title updated to '$NewTitle'"
}

Move-EntraEmployee -Username "ahall" -OldDept "Engineering" -NewDept "IT" -NewTitle "IT Administrator"
