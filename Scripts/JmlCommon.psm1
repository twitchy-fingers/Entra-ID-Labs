#Requires -Version 7.0
<#
    JmlCommon.psm1
    Shared helpers for the JML scripts: config loading, Graph connection,
    structured logging, retry, secure password generation, and lookups.
#>

$script:RepoRoot = Split-Path -Parent $PSScriptRoot
$script:LogDir   = Join-Path $script:RepoRoot 'logs'

function Get-JmlConfig {
    [CmdletBinding()]
    param([string]$Path = (Join-Path $script:RepoRoot 'config/jml-config.json'))
    if (-not (Test-Path $Path)) { throw "Config file not found: $Path" }
    Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable
}

function Get-JmlLogDirectory { $script:LogDir }

function Connect-JmlGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TenantDomain,
        [Parameter(Mandatory)][string[]]$Scopes
    )
    $ctx = Get-MgContext
    $missing = if ($ctx) { $Scopes | Where-Object { $_ -notin $ctx.Scopes } } else { $Scopes }
    if (-not $ctx -or $missing) {
        Connect-MgGraph -TenantId $TenantDomain -Scopes $Scopes -NoWelcome
    }
}

function Write-JmlLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Joiner','Mover','Leaver','RevokeSessions')][string]$Process,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$Action,
        [ValidateSet('Success','Skipped','Warning','Error','WhatIf')][string]$Result = 'Success',
        [string]$Detail = ''
    )
    if (-not (Test-Path $script:LogDir)) {
        New-Item -ItemType Directory -Path $script:LogDir -WhatIf:$false | Out-Null
    }
    $ctx = Get-MgContext
    $entry = [PSCustomObject]@{
        TimestampUtc = (Get-Date).ToUniversalTime().ToString('o')
        Operator     = if ($ctx) { $ctx.Account } else { 'unknown' }
        Process      = $Process
        Target       = $Target
        Action       = $Action
        Result       = $Result
        Detail       = $Detail
    }
    $logFile = Join-Path $script:LogDir ("jml-{0}.csv" -f (Get-Date -Format 'yyyy-MM-dd'))
    $entry | Export-Csv -Path $logFile -Append -NoTypeInformation -WhatIf:$false

    $color = @{ Success = 'Green'; Skipped = 'DarkGray'; Warning = 'Yellow'; Error = 'Red'; WhatIf = 'Cyan' }[$Result]
    $suffix = if ($Detail) { " — $Detail" } else { '' }
    Write-Host ("[{0,-7}] {1,-14} {2,-40} {3}{4}" -f $Result.ToUpper(), $Process, $Target, $Action, $suffix) -ForegroundColor $color
}

function Invoke-JmlWithRetry {
    <# Retries transient failures, such as acting on a user seconds after creation (directory replication). #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [int]$MaxAttempts = 4,
        [int]$DelaySeconds = 5
    )
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try { return & $ScriptBlock }
        catch {
            if ($attempt -eq $MaxAttempts) { throw }
            Start-Sleep -Seconds ($DelaySeconds * $attempt)
        }
    }
}

function New-JmlTempPassword {
    <# Cryptographically random password with at least one of each character class. #>
    [CmdletBinding()]
    param([ValidateRange(12, 64)][int]$Length = 16)

    $sets = @(
        'ABCDEFGHJKLMNPQRSTUVWXYZ'.ToCharArray(),
        'abcdefghijkmnopqrstuvwxyz'.ToCharArray(),
        '23456789'.ToCharArray(),
        '!@#$%^&*-_=+?'.ToCharArray()
    )
    $all = $sets | ForEach-Object { $_ }
    $rng = [System.Security.Cryptography.RandomNumberGenerator]

    $chars = [System.Collections.Generic.List[char]]::new()
    foreach ($set in $sets) { $chars.Add($set[$rng::GetInt32($set.Length)]) }
    while ($chars.Count -lt $Length) { $chars.Add($all[$rng::GetInt32($all.Count)]) }

    # Fisher-Yates shuffle
    for ($i = $chars.Count - 1; $i -gt 0; $i--) {
        $j = $rng::GetInt32($i + 1)
        $tmp = $chars[$i]; $chars[$i] = $chars[$j]; $chars[$j] = $tmp
    }
    -join $chars
}

function ConvertTo-ODataLiteral {
    param([Parameter(Mandatory)][string]$Value)
    $Value -replace "'", "''"
}

function Get-JmlUserByEmployeeId {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$EmployeeId)
    $id = ConvertTo-ODataLiteral $EmployeeId
    Get-MgUser -Filter "employeeId eq '$id'" `
        -Property Id, UserPrincipalName, DisplayName, EmployeeId, Department, JobTitle, AccountEnabled |
        Select-Object -First 1
}

function Get-JmlUniqueUpn {
    <#
        Builds a UPN using the organization's naming convention and appends 2, 3, ... on collision.
        Formats: firstInitialLastName (acoleman) or firstDotLast (aaliyah.coleman).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FirstName,
        [Parameter(Mandatory)][string]$LastName,
        [Parameter(Mandatory)][string]$Domain,
        [ValidateSet('firstInitialLastName', 'firstDotLast')][string]$Format = 'firstInitialLastName'
    )
    $first = $FirstName.Trim(); $last = $LastName.Trim()
    $raw = switch ($Format) {
        'firstInitialLastName' { "$($first.Substring(0,1))$last" }
        'firstDotLast'         { "$first.$last" }
    }
    $base = $raw.ToLowerInvariant() -replace '[^a-z0-9\.]', ''
    $candidate = "$base@$Domain"
    $n = 1
    while (Get-MgUser -Filter "userPrincipalName eq '$(ConvertTo-ODataLiteral $candidate)'" -Property Id) {
        $n++
        $candidate = "$base$n@$Domain"
    }
    $candidate
}

function Get-JmlGroupByName {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$DisplayName)
    $groups = @(Get-MgGroup -Filter "displayName eq '$(ConvertTo-ODataLiteral $DisplayName)'" `
        -Property Id, DisplayName, GroupTypes, MembershipRule)
    if ($groups.Count -gt 1) { throw "Multiple groups are named '$DisplayName'. Resolve the duplicate before continuing." }
    $groups | Select-Object -First 1
}

function Get-JmlRoleGroupNames {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Config)
    $Config.roles.Values | ForEach-Object { $_.roleGroup } | Where-Object { $_ } | Sort-Object -Unique
}

function Add-JmlGroupMember {
    <# Returns 'Added' or 'AlreadyMember'. Throws on any other error. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$GroupId,
        [Parameter(Mandatory)][string]$UserId
    )
    try {
        New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $UserId -ErrorAction Stop
        'Added'
    }
    catch {
        if ($_.Exception.Message -match 'already exist') { 'AlreadyMember' } else { throw }
    }
}

function Get-JmlPimEligibility {
    <# Returns the user's PIM-eligible Entra role assignments with readable role names. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$UserId)
    $schedules = @(Get-MgRoleManagementDirectoryRoleEligibilitySchedule -Filter "principalId eq '$UserId'" -All)
    foreach ($s in $schedules) {
        $roleName = (Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $s.RoleDefinitionId).DisplayName
        [PSCustomObject]@{
            RoleName         = $roleName
            RoleDefinitionId = $s.RoleDefinitionId
            DirectoryScopeId = $s.DirectoryScopeId
        }
    }
}

function Remove-JmlPimEligibility {
    <# Submits an adminRemove request for one eligible assignment. Caller handles ShouldProcess. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$UserId,
        [Parameter(Mandatory)][string]$RoleDefinitionId,
        [Parameter(Mandatory)][string]$DirectoryScopeId,
        [Parameter(Mandatory)][string]$Justification
    )
    New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter @{
        action           = 'adminRemove'
        principalId      = $UserId
        roleDefinitionId = $RoleDefinitionId
        directoryScopeId = $DirectoryScopeId
        justification    = $Justification
    } | Out-Null
}

Export-ModuleMember -Function *
