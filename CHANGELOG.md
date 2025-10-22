# Changelog

## Latest Updates - 2025-10-22

### 1. Upgraded to ASP.NET Core 9.0
- **Target Framework**: Updated from .NET 8.0 to .NET 9.0
- **Runtime**: Microsoft.NETCore.App 9.0.0
- **Framework**: Microsoft.AspNetCore.App 9.0.0
- **Status**: ✅ Verified in UserUpload.runtimeconfig.json

### 2. Documentation Directory Renamed
- **Change**: `docs/` → `doc/`
- **Updated Files**:
  - README.md
  - STRUCTURE.md
  - doc/DEPLOYMENT.md
  - doc/PROJECT_SUMMARY.md

### 3. Automated Build & Deployment in Terraform
- **New Feature**: Single-command deployment (`terraform apply`)
- **Added Providers**:
  - `hashicorp/archive ~> 2.0` - For creating zip packages
  - `hashicorp/null ~> 3.0` - For executing build commands

#### New Terraform Resources:
```hcl
# Build the ASP.NET application
resource "null_resource" "build_app" {
  triggers = {
    source_hash = filemd5("${local.aspnet_path}/Program.cs")
  }
  provisioner "local-exec" {
    command     = "dotnet publish -c Release -o ${local.publish_path}"
    working_dir = local.aspnet_path
  }
}

# Create zip archive
data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = local.publish_path
  output_path = local.zip_file_path
  depends_on  = [null_resource.build_app]
}

# Deploy via zip_deploy_file
resource "azurerm_windows_web_app" "app" {
  # ...
  zip_deploy_file = local.zip_file_path
  depends_on      = [data.archive_file.app_zip]
}
```

#### What Gets Automated:
1. ✅ `dotnet publish` - Builds and publishes the application
2. ✅ Zip creation - Packages the published app
3. ✅ Infrastructure provisioning - All Azure resources
4. ✅ Application deployment - Via zip deployment to App Service

#### New Local Variables:
```hcl
locals {
  suffix         = random_id.suffix.hex
  aspnet_path    = "${path.module}/../aspnet"
  publish_path   = "${path.module}/../../publish"
  zip_file_path  = "${path.module}/../../app.zip"
}
```

#### New Output:
```hcl
output "deployment_package" {
  description = "Path to the deployment zip file"
  value       = local.zip_file_path
}
```

### 4. Updated .gitignore
Added:
```gitignore
# Build outputs
publish/
app.zip
```

## Deployment Workflow Comparison

### Before (Manual - 7 steps):
```bash
1. cd src/aspnet
2. dotnet publish -c Release -o ../../publish
3. cd ../../publish
4. zip -r ../app.zip .
5. cd ..
6. Get resource names from Terraform
7. az webapp deployment source config-zip ...
```

### After (Automated - 2 steps):
```bash
1. cd src/terraform
2. terraform apply
```

## Benefits

### 1. Developer Experience
- ✅ Simpler workflow (2 commands vs 7)
- ✅ No manual build steps
- ✅ Consistent deployments
- ✅ Less error-prone

### 2. Infrastructure as Code
- ✅ Complete deployment lifecycle in Terraform
- ✅ Versioned in Git
- ✅ Reproducible builds
- ✅ Automatic on source changes

### 3. Modern Framework
- ✅ Latest .NET 9.0 features
- ✅ Performance improvements
- ✅ Security updates

## Breaking Changes

None. The project structure remains compatible with previous workflows.

## Migration Notes

If you were using manual deployment:
1. The old manual process still works
2. Documented in doc/DEPLOYMENT.md under "Manual Deployment"
3. But we recommend switching to automated Terraform deployment

## Testing

All changes validated:
- ✅ .NET 9.0 runtime confirmed
- ✅ Terraform init successful (4 providers)
- ✅ Terraform validate successful
- ✅ Test build completed successfully
- ✅ Documentation updated and reviewed

## Documentation Updates

All documentation files updated to reflect:
- ASP.NET Core 9.0 usage
- doc/ directory (not docs/)
- Automated deployment process
- Updated commands and examples

Updated files:
- README.md
- STRUCTURE.md
- doc/DEPLOYMENT.md
- doc/PROJECT_SUMMARY.md
- src/terraform/README.md

## Next Steps

1. Review the updated README.md
2. Try the new automated deployment:
   ```bash
   cd src/terraform
   terraform init
   terraform apply
   ```
3. Check doc/DEPLOYMENT.md for detailed guide

## Support

For questions or issues:
- Check doc/DEPLOYMENT.md for deployment issues
- See src/terraform/README.md for infrastructure questions
- Review STRUCTURE.md for project layout

---

**Summary**: Project enhanced with ASP.NET Core 9.0, streamlined documentation structure (doc/), and fully automated build & deployment via Terraform.
