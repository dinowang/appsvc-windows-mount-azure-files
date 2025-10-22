# Terraform State Management

## Current Configuration: Local State

This Terraform configuration uses **local state storage** by default. No remote backend is configured.

## State File Location

```
src/terraform/terraform.tfstate
```

## Important Security Notes

### ⚠️ State File Contains Sensitive Data

The Terraform state file contains:
- Resource IDs and names
- Storage account keys
- Connection strings
- Configuration details
- Resource dependencies

### 🔒 Protect Your State File

1. **Never commit to Git** - Already configured in `.gitignore`
2. **Backup regularly** - Store securely outside the repo
3. **Restrict access** - Limit who can access the state file
4. **Encrypt at rest** - Use encrypted storage for backups

## Backup Strategy

### Manual Backup

```bash
# Before making changes
cd src/terraform
cp terraform.tfstate terraform.tfstate.backup-$(date +%Y%m%d-%H%M%S)
```

### Automated Backup (Recommended)

Create a backup script:

```bash
#!/bin/bash
# backup-tfstate.sh
BACKUP_DIR="$HOME/.terraform-backups/userupload"
mkdir -p "$BACKUP_DIR"
cp src/terraform/terraform.tfstate "$BACKUP_DIR/tfstate-$(date +%Y%m%d-%H%M%S)"
# Keep only last 10 backups
ls -t "$BACKUP_DIR"/tfstate-* | tail -n +11 | xargs rm -f
```

## State File Ignore Configuration

The `.gitignore` file includes:

```gitignore
# Terraform state files
src/terraform/*.tfstate
src/terraform/*.tfstate.backup
```

This ensures state files are **never committed** to version control.

## Team Collaboration

### Problem with Local State

Local state is **not suitable** for team environments because:
- ❌ No state locking (risk of conflicts)
- ❌ No state sharing (team members can't collaborate)
- ❌ No state versioning (can't rollback)
- ❌ State stored on individual machines

### Solution: Remote Backend

For team environments, migrate to a remote backend.

#### Option 1: Azure Storage Backend

1. Create a storage account for Terraform state:

```bash
# Create resource group for Terraform state
az group create \
  --name terraform-state-rg \
  --location eastus

# Create storage account
az storage account create \
  --name tfstateXXXXXX \
  --resource-group terraform-state-rg \
  --location eastus \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name tfstate \
  --account-name tfstateXXXXXX
```

2. Update `main.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateXXXXXX"
    container_name       = "tfstate"
    key                  = "userupload.tfstate"
  }
  
  required_providers {
    # ... existing providers
  }
}
```

3. Migrate existing state:

```bash
terraform init -migrate-state
```

#### Option 2: Terraform Cloud

1. Create account at https://app.terraform.io
2. Create workspace
3. Update `main.tf`:

```hcl
terraform {
  cloud {
    organization = "your-org"
    workspaces {
      name = "userupload"
    }
  }
  
  required_providers {
    # ... existing providers
  }
}
```

4. Login and migrate:

```bash
terraform login
terraform init
```

## State Operations

### View State

```bash
cd src/terraform
terraform show
```

### List Resources in State

```bash
terraform state list
```

### Remove Resource from State

```bash
# Example: Remove a resource without destroying it
terraform state rm azurerm_resource_group.rg
```

### Import Existing Resource

```bash
# Example: Import an existing resource
terraform import azurerm_resource_group.rg /subscriptions/{sub-id}/resourceGroups/{rg-name}
```

## State Recovery

### Lost State File

If you lose your state file:

1. **Check backups** - Restore from backup
2. **Import resources** - Manually import each resource
3. **Recreate** - Last resort, may require destroying and recreating

### Corrupted State

```bash
# Terraform automatically creates backups
cp terraform.tfstate.backup terraform.tfstate
```

## Best Practices

### For Individual Development (Current Setup)

✅ **Use local state** (current configuration)
✅ **Backup regularly** (manual or automated)
✅ **Keep .gitignore** (state files excluded)
✅ **Secure your machine** (state contains secrets)

### For Team Environments

✅ **Use remote backend** (Azure Storage or Terraform Cloud)
✅ **Enable state locking** (prevents concurrent modifications)
✅ **Use workspaces** (separate environments)
✅ **Implement RBAC** (control who can modify state)

### For Production

✅ **Remote backend required** (no exceptions)
✅ **Enable versioning** (state history)
✅ **Enable encryption** (data at rest)
✅ **Regular backups** (automated)
✅ **State locking** (prevent conflicts)
✅ **Audit logging** (track changes)

## Troubleshooting

### State Lock Issues

If state is locked:

```bash
# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

### State Drift

Check for differences between state and actual infrastructure:

```bash
terraform plan -refresh-only
```

### State Debugging

```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform plan
```

## Summary

- ✅ **Current setup**: Local state (suitable for individual development)
- ⚠️ **Security**: State file contains sensitive data - keep it secure
- 🔒 **Git**: State files are excluded via `.gitignore`
- 💾 **Backup**: Create regular backups of your state file
- 👥 **Teams**: Consider migrating to remote backend for collaboration

For more information:
- [Terraform State Documentation](https://www.terraform.io/docs/language/state/index.html)
- [Azure Backend Configuration](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
- [Terraform Cloud](https://www.terraform.io/cloud)
