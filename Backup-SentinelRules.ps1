#requires -Version 7.2
<#
.SYNOPSIS
Exports Microsoft Sentinel analytics and automation rules to one JSON file.
.DESCRIPTION
Uses read-only Azure CLI requests and follows all result pages. Includes enabled
and disabled rules, retaining their IDs, kinds, properties, and reference IDs.
Requires Azure CLI, an existing az login session, and read access to both rule
types in the workspace (for example, Microsoft Sentinel Reader).

The JSON is a configuration snapshot, not an ARM deployment template.
Referenced playbooks, connections, watchlists, parsers, and other dependencies
are not exported. Protect the output as sensitive configuration.
.EXAMPLE
.\Backup-SentinelRules.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000" `
    -WorkspaceResourceGroup "rg-sentinel" -WorkspaceName "law-sentinel" `
    -OutputPath ".\Sentinel-Rules.json"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [guid] $SubscriptionId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $WorkspaceResourceGroup,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $WorkspaceName,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (
        Join-Path $PWD ("Sentinel-Rules-{0}.json" -f
            [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Get-Command az -ErrorAction Stop | Out-Null

function Invoke-AzJson {
    param([Parameter(Mandatory)][string[]] $CliArguments)

    $output = & az @CliArguments --only-show-errors --output json
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI failed (exit $LASTEXITCODE): az $($CliArguments -join ' '). No backup was committed."
    }
    $json = $output -join "`n"
    if ([string]::IsNullOrWhiteSpace($json)) {
        throw "Azure CLI returned an empty response: az $($CliArguments -join ' ')"
    }
    return ConvertFrom-Json -InputObject $json -AsHashtable -Depth 100
}

function Get-AllRules {
    param([Parameter(Mandatory)][string] $Url)

    $visited = [Collections.Generic.HashSet[string]]::new()
    do {
        $uri = [uri] $Url
        if ($uri.Scheme -ne 'https' -or
            $uri.Authority -ne ([uri] $script:ArmEndpoint).Authority) {
            throw "Refusing an unexpected ARM URL: $Url"
        }
        if (-not $visited.Add($Url)) {
            throw "ARM returned a repeated pagination URL: $Url"
        }
        $page = Invoke-AzJson -CliArguments @(
            'rest', '--method', 'get', '--url', $Url,
            '--subscription', $SubscriptionId.ToString()
        )
        if ($page -isnot [Collections.IDictionary] -or
            -not $page.ContainsKey('value') -or $page['value'] -isnot [array]) {
            throw "Expected an ARM collection with a value array: $Url"
        }
        foreach ($rule in $page['value']) {
            $rule
        }
        $Url = if ($page.ContainsKey('nextLink')) { $page['nextLink'] } else { $null }
    } while (-not [string]::IsNullOrWhiteSpace($Url))
}

$destination = [IO.Path]::GetFullPath($OutputPath)
if (Test-Path -LiteralPath $destination) {
    throw "Output already exists. Choose a new OutputPath: $destination"
}
$parent = Split-Path -Parent $destination
if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    throw "Output directory does not exist: $parent"
}

$startedUtc = [DateTime]::UtcNow.ToString('o')
$account = Invoke-AzJson -CliArguments @(
    'account', 'show', '--subscription', $SubscriptionId.ToString()
)
$cloud = Invoke-AzJson -CliArguments @('cloud', 'show')
$script:ArmEndpoint = $cloud['endpoints']['resourceManager'].TrimEnd('/')
$workspaceId = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}' -f
    $SubscriptionId, [uri]::EscapeDataString($WorkspaceResourceGroup), [uri]::EscapeDataString($WorkspaceName)
$apiVersion = '2025-09-01'
$baseUrl = "$script:ArmEndpoint$workspaceId/providers/Microsoft.SecurityInsights"

Write-Host 'Exporting analytics rules...'
$analyticsRules = @(Get-AllRules -Url ("{0}/alertRules?api-version={1}" -f $baseUrl, $apiVersion))
Write-Host 'Exporting automation rules...'
$automationRules = @(Get-AllRules -Url ("{0}/automationRules?api-version={1}" -f $baseUrl, $apiVersion))

$backup = [ordered]@{
    schemaVersion = '1.0'
    backupType = 'MicrosoftSentinelRules'
    isArmDeploymentTemplate = $false
    startedUtc = $startedUtc
    completedUtc = [DateTime]::UtcNow.ToString('o')
    apiVersion = $apiVersion
    source = [ordered]@{
        tenantId = $account['tenantId']
        subscriptionId = $SubscriptionId.ToString()
        cloud = $cloud['name']
        workspaceResourceGroup = $WorkspaceResourceGroup
        workspaceName = $WorkspaceName
        workspaceResourceId = $workspaceId
    }
    counts = [ordered]@{
        analyticsRules = $analyticsRules.Count
        automationRules = $automationRules.Count
    }
    limitations = @(
        'Analytics and automation rule definitions only; referenced resources are not exported.',
        'Not an ARM template; restore requires supported create/update payloads and dependency mapping.',
        'Rule states are preserved; review automated actions before enabling restored rules.',
        'Multi-request export is not a transactionally consistent point-in-time snapshot.'
    )
    analyticsRules = $analyticsRules
    automationRules = $automationRules
}

$temporaryPath = Join-Path $parent ('.sentinel-rules-{0}.tmp' -f [guid]::NewGuid())
try {
    $json = ConvertTo-Json -InputObject $backup -Depth 100 -WarningAction Stop
    [IO.File]::WriteAllText($temporaryPath, $json, [Text.UTF8Encoding]::new($false))
    $verified = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($temporaryPath)) -AsHashtable -Depth 100
    if ($verified['analyticsRules'].Count -ne $analyticsRules.Count -or
        $verified['automationRules'].Count -ne $automationRules.Count) {
        throw 'Backup validation failed: rule count mismatch.'
    }
    [IO.File]::Move($temporaryPath, $destination)
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}

Write-Host "Saved $($analyticsRules.Count) analytics rules and $($automationRules.Count) automation rules to: $destination"
