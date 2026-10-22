# Microsoft Sentinel Rules Backup

Back up **analytics rules and automation rules** from a Microsoft Sentinel workspace to a single JSON file using PowerShell and Azure CLI.

Script: [Backup-SentinelRules.ps1](./Backup-SentinelRules.ps1)

> This script exports configuration only. It does not modify Azure resources, restore rules, or create a complete disaster recovery backup.

## What the script does

The script:

1. Reads the specified subscription's account metadata and the current Azure cloud's Resource Manager endpoint.
2. Uses `az rest` to call the Microsoft Sentinel `alertRules` and `automationRules` list endpoints for one workspace, using API version `2025-09-01`.
3. Follows pagination links until all pages for both rule types have been retrieved.
4. Retains the full rule objects returned by those APIs, including IDs, rule kinds where present, properties, and references to other resources. Both enabled and disabled rules are included; the script does not filter by rule state.
5. Adds source workspace details, UTC export timestamps, API version, limitations, and counts for each rule type.
6. Serializes the result to UTF-8 JSON, reads it back, and checks that the rule counts match before moving the temporary file to the requested destination.

The script does not change the active Azure CLI subscription. Requests explicitly specify the subscription provided through `-SubscriptionId`.

### Safety behavior

- Makes only read requests to Azure.
- Refuses to overwrite an existing output file.
- Stops on Azure CLI errors, invalid collection responses, unexpected pagination hosts, or repeated pagination links.
- Does not commit a final JSON file if either rule export or output validation fails.
- Removes its temporary output file during normal error handling.
- Preserves empty rule collections as JSON arrays with a count of zero.
- Stops rather than silently accepting JSON serialization depth truncation.

The export involves multiple requests. It is **not a transactionally consistent point-in-time snapshot** if rules change while the script is running.

## Prerequisites

- **PowerShell 7.2 or later**. Windows PowerShell 5.1 is not supported.
- **Azure CLI**, installed and available as `az`.
- An authenticated Azure CLI session in the appropriate tenant and Azure cloud.
- Read access to both rule types in the target Sentinel workspace, for example through the **Microsoft Sentinel Reader** role at the appropriate scope.
- An existing, writable destination directory.

You can run the script locally or in **Azure Cloud Shell using PowerShell**. In Cloud Shell, upload the script first and download the resulting JSON or save it to configured persistent storage before ending the session.

Installation references:

- [Install PowerShell](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
- [Install Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)

## Quick start

1. Download [Backup-SentinelRules.ps1](./Backup-SentinelRules.ps1). On GitHub, use the file's **Raw** or download option to save the actual script rather than the HTML page.
2. Open PowerShell 7.2 or later in the directory containing the script.
3. Replace the placeholder subscription ID, resource group, and workspace name below.
4. Run:

```powershell
# Skip this if already signed in, such as in Azure Cloud Shell.
az login

.\Backup-SentinelRules.ps1 `
    -SubscriptionId "00000000-0000-0000-0000-000000000000" `
    -WorkspaceResourceGroup "rg-sentinel" `
    -WorkspaceName "law-sentinel" `
    -OutputPath "Sentinel-Rules-Backup.json"
```

`WorkspaceResourceGroup` must be the resource group containing the Log Analytics workspace on which Sentinel is enabled. `WorkspaceName` is that workspace's name, not a separate Sentinel resource name.

If your account uses multiple tenants, sign in to the appropriate tenant with `az login --tenant "<tenant-id>"` instead.

The example output path is relative to your current directory. Choose a new filename for each run, or omit `-OutputPath` to use an automatically generated UTC timestamped filename:

```powershell
.\Backup-SentinelRules.ps1 `
    -SubscriptionId "00000000-0000-0000-0000-000000000000" `
    -WorkspaceResourceGroup "rg-sentinel" `
    -WorkspaceName "law-sentinel"
```

### Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| `SubscriptionId` | Yes | Subscription GUID containing the workspace. |
| `WorkspaceResourceGroup` | Yes | Resource group containing the workspace. |
| `WorkspaceName` | Yes | Name of the Sentinel-enabled Log Analytics workspace. |
| `OutputPath` | No | Destination JSON file. Defaults to `Sentinel-Rules-<UTC timestamp>.json` in the current directory. The parent directory must exist; an existing file is never overwritten. |

## Output

The single JSON file contains:

| Field | Contents |
| --- | --- |
| `schemaVersion` | Backup file format version, currently `1.0`. |
| `backupType` | `MicrosoftSentinelRules`. |
| `isArmDeploymentTemplate` | `false`; this file cannot be deployed directly as an ARM template. |
| `startedUtc`, `completedUtc` | UTC collection start and completion timestamps. |
| `apiVersion` | Sentinel API version used for the export. |
| `source` | Tenant, subscription, cloud, resource group, workspace name, and workspace resource ID. |
| `counts` | Number of exported analytics rules and automation rules. |
| `limitations` | Scope and restoration caveats recorded with the backup. |
| `analyticsRules` | Array of full analytics rule objects returned by the API. |
| `automationRules` | Array of full automation rule objects returned by the API. |

For example, a successful run might report:

```text
Exporting analytics rules...
Exporting automation rules...
Saved 42 analytics rules and 6 automation rules to: <absolute output path>
```

### Inspect the backup

```powershell
$backup = Get-Content -LiteralPath ".\Sentinel-Rules-Backup.json" -Raw |
    ConvertFrom-Json -Depth 100

$backup.counts

$backup.analyticsRules | ForEach-Object {
    [pscustomobject]@{
        Id          = $_.id
        DisplayName = $_.properties.displayName
        Kind        = $_.kind
    }
}

$backup.automationRules | ForEach-Object {
    [pscustomobject]@{
        Id          = $_.id
        DisplayName = $_.properties.displayName
    }
}
```

## What is not backed up

The script exports **only the two rule types**, plus descriptive backup metadata. It does not export:

- Playbook definitions, Logic Apps, API connections, or their authentication credentials.
- Workbooks.
- Watchlists or watchlist items.
- Parsers, functions, saved searches, or hunting queries.
- Data connectors, data collection rules, tables, or ingestion configuration.
- Content Hub solution packages or uninstantiated rule templates.
- Log data, incidents, alerts, or investigation history.
- Managed identities, role assignments, secrets, certificates, or Key Vault resources.
- Resources from other workspaces or subscriptions.

References to dependencies remain in exported rule properties, but the script does not follow those references or copy the referenced resources.

## Can this JSON be used for restoration?

**Yes, as input to a separately implemented and tested restore process. No, not as a directly deployable template or a complete disaster recovery solution.**

A restore process must:

1. Prepare the target workspace and required dependencies.
2. Convert each exported rule into the supported create/update request payload for its rule type, excluding read-only fields.
3. Map workspace, subscription, resource group, rule, and playbook references where the destination differs.
4. Restore analytics rules before automation rules that depend on them.
5. Reestablish permissions and dependencies, then validate detection and response behavior.

Some rule kinds may have service-specific prerequisites or restrictions. A successful export does not guarantee that every rule can be recreated unchanged in a different workspace or region.

> Exported rule states are preserved. Review enabled states, expiration settings, and automated actions before restoration to avoid duplicate detections or unintended playbook execution.

No restore functionality is included in this script.

## Backup storage recommendations

- Treat the JSON as sensitive security configuration.
- Do not commit real backup files to a public GitHub repository.
- Store copies in access-controlled, encrypted storage outside the source failure domain.
- Use versioning and retention appropriate to your recovery requirements.
- Schedule exports according to your required recovery point objective.
- Test restoration in a nonproduction workspace and document missing dependencies.

## Troubleshooting

| Symptom | Action |
| --- | --- |
| `az` is not recognized | Install Azure CLI and reopen PowerShell. |
| PowerShell version requirement fails | Run with PowerShell 7.2 or later, not Windows PowerShell 5.1. |
| Sign-in or subscription access error | Authenticate to the appropriate tenant and verify access to the supplied subscription. |
| HTTP `403` | Check read permissions for both analytics and automation rules at the workspace or a parent scope. |
| HTTP `404` | Verify the subscription ID, workspace resource group, workspace name, and Sentinel onboarding. |
| Output already exists | Choose another filename or omit `-OutputPath` for a timestamped filename. |
| Output directory does not exist | Create the parent directory or select an existing writable directory. |
| HTTP `429` or a transient service error | The script stops rather than saving a partial backup. Wait and rerun after the service permits requests. |

## Validation status

The script passed PowerShell syntax checks and mocked Azure CLI tests covering pagination, both rule types, enabled and disabled states, nested properties, dependency references, empty results, overwrite protection, and error handling.

These tests do not replace validation against your own Azure environment or a restore drill.

## References

- [Microsoft Sentinel: Alert Rules - List](https://learn.microsoft.com/rest/api/securityinsights/alert-rules/list?view=rest-securityinsights-2025-09-01)
- [Microsoft Sentinel: Automation Rules - List](https://learn.microsoft.com/rest/api/securityinsights/automation-rules/list?view=rest-securityinsights-2025-09-01)
- [Microsoft Sentinel business continuity and disaster recovery](https://learn.microsoft.com/azure/sentinel/business-continuity-disaster-recovery)
