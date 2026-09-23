# Microsoft Sentinel Analytics Rules

This directory contains the deployable ARM templates for the repository's custom Microsoft Sentinel analytics rules.

## Deployment

The Microsoft Sentinel repository connection runs the generated workflow in `.github/workflows/` after changes are pushed to `main`. That workflow recursively discovers `.json` and `.bicep` files and deploys supported resources to the connected workspace.

The YAML files in the repository root are source definitions only. The generated Microsoft Sentinel workflow does not deploy YAML files directly.

## Rules

| Template | Kind |
|---|---|
| `nrt-malicious-inbox-rule.json` | NRT |
| `pe-file-dropped-in-color-profile-folder.json` | Scheduled |
| `rare-subscription-level-operations.json` | Scheduled |

Each template uses the same rule ID as its corresponding YAML source. Deploying a changed template therefore updates the existing Sentinel rule instead of creating a duplicate.

## Making changes

1. Edit the appropriate JSON template.
2. Validate that the file contains valid JSON.
3. Commit and push the change to `main`.
4. Review the generated GitHub Actions deployment.
5. Confirm the updated rule in Microsoft Sentinel.

Do not commit exported credentials, client secrets, access tokens, or tenant-specific parameter files.
