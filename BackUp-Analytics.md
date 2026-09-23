<div align="center">

# Export Microsoft Sentinel Analytics Rules

### Back up your complete analytics rule inventory to JSON with one Azure CLI command

[![Azure CLI](https://img.shields.io/badge/Azure%20CLI-Required-0078D4?logo=microsoftazure)](https://learn.microsoft.com/cli/azure/install-azure-cli)
[![Microsoft Sentinel](https://img.shields.io/badge/Microsoft-Sentinel-5C2D91?logo=microsoft)](https://learn.microsoft.com/azure/sentinel/)
[![Output](https://img.shields.io/badge/Output-JSON-2EA44F)](#output)

</div>

---

## Overview

This command exports every analytics rule from a Microsoft Sentinel workspace to a local JSON file. The resulting file can be used for:

- Rule inventory and documentation
- Configuration backups
- Change tracking and source control
- MITRE ATT&CK coverage analysis
- Workspace migration planning
- Security posture reviews

## Prerequisites

Before running the command:

1. Install the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli).
2. Sign in to Azure:

   ```bash
   az login
   ```

3. Select the correct subscription if your account has access to more than one:

   ```bash
   az account set --subscription "<subscription-id-or-name>"
   ```

4. Ensure your account can read Microsoft Sentinel analytics rules in the target workspace.

## Export the Rules

Replace the placeholder values with your Microsoft Sentinel resource group and Log Analytics workspace name.

### Bash, Azure Cloud Shell, macOS, or Linux

```bash
az sentinel alert-rule list \
  --resource-group SENTINEL-RG \
  --workspace-name LOGANALYTICSWORKSPACENAME \
  --output json > analytics-rules.json
```

### PowerShell

```powershell
az sentinel alert-rule list `
  --resource-group "SENTINEL-RG" `
  --workspace-name "LOGANALYTICSWORKSPACENAME" `
  --output json |
  Set-Content -Path ".\analytics-rules.json" -Encoding utf8
```

## Parameters

| Parameter | Description | Example |
|---|---|---|
| `--resource-group` | Resource group containing the Log Analytics workspace | `sentinel-production-rg` |
| `--workspace-name` | Log Analytics workspace connected to Microsoft Sentinel | `law-sentinel-production` |
| `--output json` | Returns the complete rule collection in JSON format | `json` |
| `analytics-rules.json` | Local destination file for the exported rules | `./analytics-rules.json` |

## Output

The command creates:

```text
analytics-rules.json
```

The JSON output includes the available configuration for each rule, such as:

- Rule ID and display name
- Rule type
- Enabled state
- Severity
- KQL query
- Query frequency and period
- Trigger conditions
- MITRE ATT&CK tactics and techniques
- Entity mappings
- Incident creation settings
- Event grouping settings

> [!IMPORTANT]
> The export can contain internal detection logic, workspace configuration, and entity mappings. Review the file before committing it to a public repository.

## Validate the Export

Confirm that the file was created and contains valid JSON.

### Bash

```bash
jq length analytics-rules.json
```

### PowerShell

```powershell
$rules = Get-Content ".\analytics-rules.json" -Raw | ConvertFrom-Json
Write-Host "Exported $($rules.Count) analytics rules."
```

## Troubleshooting

### The `sentinel` command is not recognized

Install or update the Microsoft Sentinel Azure CLI extension:

```bash
az extension add --name sentinel
az extension update --name sentinel
```

### The workspace cannot be found

Verify the resource group and workspace name:

```bash
az monitor log-analytics workspace show \
  --resource-group SENTINEL-RG \
  --workspace-name LOGANALYTICSWORKSPACENAME
```

### The request is forbidden

Confirm that the signed-in account has a role that permits reading Microsoft Sentinel analytics rules at the workspace or resource-group scope.

## Reference

- [Azure CLI: `az sentinel alert-rule list`](https://learn.microsoft.com/cli/azure/sentinel/alert-rule?view=azure-cli-latest#az-sentinel-alert-rule-list)
- [Install the Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [Microsoft Sentinel documentation](https://learn.microsoft.com/azure/sentinel/)

