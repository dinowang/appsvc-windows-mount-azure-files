# Deployment Guide - UserUpload Application

This guide walks you through deploying the UserUpload application to Azure using Terraform.

## Prerequisites

1. **Azure Account**: Active Azure subscription
2. **Azure CLI**: Installed and configured (optional, only for manual deployment)
3. **Terraform**: Version 1.0 or later
4. **.NET SDK**: Version 9.0 or later (Terraform will use this to build the app)

## Step-by-Step Deployment

### 1. Authenticate with Azure

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Understand Resource Naming

Terraform automatically generates a 6-character random hex suffix for all resources to ensure global uniqueness:

**Example resource names** (XXXXXX = random hex):
- Storage Account: `storuseruploadXXXXXX`
- App Service: `web-userupload-XXXXXX`
- App Service Plan: `plan-userupload-XXXXXX`
- Resource Group: `rg-userupload-XXXXXX`

The suffix is automatically generated and shared across all resources. To customize base names or region, create a `terraform.tfvars` file:

```hcl
resource_group_name   = "rg-myapp"
storage_account_name  = "stormyapp"
app_service_plan_name = "plan-myapp"
app_service_name      = "web-myapp"
location              = "East US"
```

### 3. Deploy Infrastructure and Application (Automated)

Terraform will automatically build, package, and deploy your application:

```bash
cd src/terraform

# Initialize Terraform
terraform init

# Preview changes (including build plan)
terraform plan

# Deploy infrastructure and application
terraform apply
```

Type `yes` when prompted to confirm the deployment.

**What Terraform Does Automatically:**
1. ✅ Builds the ASP.NET Core 9.0 application
2. ✅ Creates a deployment zip package
3. ✅ Provisions Azure infrastructure (App Service, Storage, etc.)
4. ✅ Deploys the application via zip deployment

### 4. Verify Deployment

After deployment completes, Terraform outputs will show all resource names including the random suffix:

```bash
cd src/terraform
terraform output
```

Key outputs:
- `naming_suffix` - The random 6-character hex suffix used
- `app_service_url` - URL to access your application
- `resource_group_name` - Full resource group name with suffix
- `storage_account_name` - Full storage account name with suffix

Open the `app_service_url` in your browser to access the application.

## Manual Deployment (Alternative)

If you prefer to build and deploy manually:

### 1. Build and Package

```bash
# Build the application
cd src/aspnet
dotnet publish -c Release -o ../../publish

# Create zip package
cd ../../publish
zip -r ../app.zip .
cd ..
```

### 2. Deploy to Azure App Service

```bash
# Get resource names from Terraform
RESOURCE_GROUP=$(cd src/terraform && terraform output -raw resource_group_name)
APP_SERVICE=$(cd src/terraform && terraform output -raw app_service_name)

# Deploy using Azure CLI
az webapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE \
  --src app.zip
```

## Post-Deployment Configuration

### Update Upload Path (Optional)

To use the mounted Azure File Share for uploads, update the application's upload path:

1. Set an app setting in Azure:
```bash
RESOURCE_GROUP=$(cd src/terraform && terraform output -raw resource_group_name)
APP_SERVICE=$(cd src/terraform && terraform output -raw app_service_name)

az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE \
  --settings UPLOAD_PATH="/mounts/uploads"
```

2. Modify the application code to read from this setting.

### Enable Application Insights (Recommended)

```bash
RESOURCE_GROUP=$(cd src/terraform && terraform output -raw resource_group_name)
APP_SERVICE=$(cd src/terraform && terraform output -raw app_service_name)
SUFFIX=$(cd src/terraform && terraform output -raw naming_suffix)

az monitor app-insights component create \
  --app userupload-insights-$SUFFIX \
  --location eastus \
  --resource-group $RESOURCE_GROUP

# Link to App Service
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE \
  --settings APPINSIGHTS_INSTRUMENTATIONKEY="<your-key>"
```

## Accessing Azure File Share

The Azure File Share is mounted at `/mounts/uploads` on the App Service. Files uploaded through the application can persist here.

To access the file share directly:

```bash
RESOURCE_GROUP=$(cd src/terraform && terraform output -raw resource_group_name)
STORAGE_ACCOUNT=$(cd src/terraform && terraform output -raw storage_account_name)

# Get storage account key
az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT

# Mount locally (example for Linux/macOS)
sudo mkdir /mnt/useruploads
sudo mount -t cifs //$STORAGE_ACCOUNT.file.core.windows.net/userupload-files /mnt/useruploads -o username=$STORAGE_ACCOUNT,password=<storage-key>
```

## Troubleshooting

### Application Won't Start

Check application logs:
```bash
RESOURCE_GROUP=$(cd src/terraform && terraform output -raw resource_group_name)
APP_SERVICE=$(cd src/terraform && terraform output -raw app_service_name)

az webapp log tail \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE
```

### File Upload Issues

1. Check storage account connection:
```bash
RESOURCE_GROUP=$(cd src/terraform && terraform output -raw resource_group_name)
STORAGE_ACCOUNT=$(cd src/terraform && terraform output -raw storage_account_name)

az storage share show \
  --name userupload-files \
  --account-name $STORAGE_ACCOUNT
```

2. Verify mount configuration in App Service:
```bash
RESOURCE_GROUP=$(cd src/terraform && terraform output -raw resource_group_name)
APP_SERVICE=$(cd src/terraform && terraform output -raw app_service_name)

az webapp config storage-account list \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE
```

### Resource Name Conflicts

Resource name conflicts should be rare due to automatic random suffix generation. If you still encounter naming issues:
1. Update the base names in `src/terraform/variables.tf` or use a `terraform.tfvars` file
2. Destroy and recreate to get a new random suffix: `terraform destroy && terraform apply`

## Cleanup

To remove all deployed resources:

```bash
cd src/terraform
terraform destroy
```

Type `yes` when prompted to confirm deletion.

## Cost Estimates

Approximate monthly costs (may vary by region):
- **App Service Plan (P0v3)**: ~$100-150/month
- **Storage Account**: ~$5-10/month (depending on usage)
- **Total**: ~$105-160/month

To reduce costs for development/testing:
- Use B1 (Basic) tier instead of P0v3
- Stop the App Service when not in use

## Additional Resources

- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure Files Documentation](https://docs.microsoft.com/azure/storage/files/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
