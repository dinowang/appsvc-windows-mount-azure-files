# Terraform Configuration for UserUpload Application

This Terraform configuration provisions the required Azure resources for the UserUpload ASP.NET Core application.

## Features

- **Automated Build & Deploy**: Builds ASP.NET Core 9.0 app and deploys via zip
- **Random Naming**: All resources get unique 6-character hex suffix
- **Infrastructure as Code**: Complete Azure environment in one apply
- **Local State**: Uses local terraform.tfstate file (not remote backend)
- **Managed Identity**: Uses Azure AD authentication, no storage account keys

## Resources Provisioned

All resources are automatically suffixed with a 6-character random hex string for global uniqueness.

- **Resource Group**: `rg-userupload-XXXXXX` - Container for all resources
- **Storage Account**: `storuseruploadXXXXXX` - Storage account with Azure Files enabled
- **Azure File Share**: `userupload-files` - File share for persistent storage
- **App Service Plan**: `plan-userupload-XXXXXX` - Windows-based P0v3 tier
- **App Service**: `web-userupload-XXXXXX` - Windows web app with mounted Azure File Share

Where `XXXXXX` is a randomly generated 6-character hex suffix shared across all resources.

## Prerequisites

1. Azure CLI installed and authenticated
2. Terraform installed (version 1.0+)
3. .NET 9.0 SDK installed (for building the application)
4. Valid Azure subscription

## Usage

### Initialize Terraform

```bash
cd terraform
terraform init
```

### Review the Plan

```bash
terraform plan
```

### Apply the Configuration

```bash
terraform apply
```

**What happens automatically:**
1. Builds the ASP.NET Core 9.0 application
2. Creates a deployment zip package
3. Provisions all Azure resources
4. Deploys the application to App Service

### Destroy Resources (when needed)

```bash
terraform destroy
```

## Configuration

The configuration uses default values defined in `variables.tf`. You can customize these by:

1. **Creating a `terraform.tfvars` file:**

```hcl
resource_group_name   = "rg-userupload"
location              = "East US"
storage_account_name  = "storuserupload"
app_service_plan_name = "plan-userupload"
app_service_name      = "web-userupload"
environment           = "production"
```

2. **Using command-line variables:**

```bash
terraform apply -var="location=West US" -var="environment=staging"
```

## Outputs

After successful deployment, Terraform will output:

- Resource group name
- App Service URL
- Storage account name
- File share name
- App Service Plan name
- App Service name

## Azure File Share Mount

The Azure File Share is automatically mounted to the App Service at `/mounts/uploads`. The application can use this path to store uploaded files persistently across app restarts and scale-out scenarios.

## Random Naming Suffix

The configuration automatically generates a 6-character random hex suffix using the Terraform `random` provider. This suffix is:
- Shared across all resources for consistency
- Ensures global uniqueness for Storage Account and App Service names
- Stored in Terraform state for persistence across deployments
- Output as `naming_suffix` for reference

## State Management

This configuration uses **local state** storage. The `terraform.tfstate` file is created in the `src/terraform/` directory.

**Important Notes:**
- ⚠️ **Backup your state file** - It contains sensitive information and is critical for managing resources
- 🔒 **Keep state file secure** - Contains resource IDs, connection strings, and configuration
- 👥 **Not for team use** - For team environments, consider using a remote backend (Azure Storage, Terraform Cloud)
- 📁 **State file location**: `src/terraform/terraform.tfstate`

### For Team Environments (Optional)

If working in a team, add a backend configuration:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatestorage"
    container_name       = "tfstate"
    key                  = "userupload.tfstate"
  }
}
```

## Notes

- All resources automatically receive the random suffix for uniqueness
- The P0v3 SKU provides premium performance for production workloads
- Files uploaded to the mounted path will persist in Azure Files storage
- Once created, the random suffix persists across terraform apply/destroy cycles (stored in state)
- Local state is stored in `terraform.tfstate` - ensure it's backed up and secure
