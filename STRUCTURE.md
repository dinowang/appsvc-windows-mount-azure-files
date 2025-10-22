# Project Structure Reference

Quick reference for the UserUpload project structure.

## Directory Layout

```
UserUpload/
│
├── doc/                          📚 All documentation files
│   ├── DEPLOYMENT.md              → Azure deployment guide
│   └── PROJECT_SUMMARY.md         → Complete project overview
│
├── src/                           💻 All source code
│   ├── aspnet/                    → ASP.NET Core web application
│   │   ├── Pages/                 → Razor pages
│   │   │   ├── Shared/            → Shared layouts
│   │   │   ├── Upload.cshtml      → File upload page (UI)
│   │   │   └── Upload.cshtml.cs   → File upload logic
│   │   ├── Properties/            → Launch settings
│   │   ├── wwwroot/               → Static files (CSS, JS)
│   │   ├── Program.cs             → Application entry point
│   │   ├── UserUpload.csproj      → Project configuration
│   │   └── appsettings.json       → App configuration
│   │
│   └── terraform/                 → Infrastructure as Code
│       ├── main.tf                → Main Terraform config
│       ├── variables.tf           → Variable definitions
│       ├── outputs.tf             → Output values
│       ├── README.md              → Terraform docs
│       └── RANDOM_SUFFIX.md       → Suffix feature guide
│
├── .gitignore                     🚫 Git ignore rules
├── CHANGELOG.md                   📝 Change history
├── PROMPTS.md                     💬 All creation prompts
├── README.md                      📖 Main project documentation
└── STRUCTURE.md                   📋 This file
```

## Quick Commands

### Development

```bash
# Run application locally
cd src/aspnet
dotnet run

# Build application
cd src/aspnet
dotnet build

# Run tests (when available)
cd src/aspnet
dotnet test
```

### Infrastructure

```bash
# Initialize Terraform
cd src/terraform
terraform init

# Preview infrastructure changes
terraform plan

# Deploy infrastructure
terraform apply

# View outputs
terraform output

# Destroy infrastructure
terraform destroy
```

### Automated Deployment

```bash
# One command to build and deploy everything!
cd src/terraform
terraform init
terraform apply

# Terraform automatically handles:
# 1. Building ASP.NET Core 9.0 app
# 2. Creating deployment zip
# 3. Provisioning infrastructure
# 4. Deploying application to Azure
```

### Manual Deployment (Alternative)

```bash
# Build for production
cd src/aspnet
dotnet publish -c Release -o ../../publish

# Package application
cd ../../publish
zip -r ../app.zip .

# Deploy to Azure
cd ..
RESOURCE_GROUP=$(cd src/terraform && terraform output -raw resource_group_name)
APP_SERVICE=$(cd src/terraform && terraform output -raw app_service_name)

az webapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE \
  --src app.zip
```

## File Purposes

### Documentation (`doc/`)

| File | Purpose |
|------|---------|
| `DEPLOYMENT.md` | Step-by-step Azure deployment instructions |
| `PROJECT_SUMMARY.md` | Comprehensive project overview and features |

### Application Code (`src/aspnet/`)

| File/Folder | Purpose |
|-------------|---------|
| `Pages/Upload.cshtml` | File upload UI (HTML/Razor) |
| `Pages/Upload.cshtml.cs` | File upload backend logic |
| `Pages/Shared/_Layout.cshtml` | Site layout template |
| `Program.cs` | Application startup and configuration |
| `UserUpload.csproj` | .NET project file |
| `wwwroot/` | Static assets (CSS, JavaScript, images) |

### Infrastructure (`src/terraform/`)

| File | Purpose |
|------|---------|
| `main.tf` | Azure resources definition |
| `variables.tf` | Configurable parameters |
| `outputs.tf` | Exported values after deployment |
| `README.md` | Terraform-specific documentation |
| `RANDOM_SUFFIX.md` | Random naming suffix documentation |
| `STATE_MANAGEMENT.md` | State file management and security guide |
| `terraform.tfstate` | Local state file (gitignored, backup regularly!) |

## Navigation Tips

- **Starting point**: Read `README.md` first
- **Want to deploy?**: See `doc/DEPLOYMENT.md`
- **Need details?**: Check `doc/PROJECT_SUMMARY.md`
- **Working with infrastructure?**: Go to `src/terraform/`
- **Developing features?**: Navigate to `src/aspnet/`

## Paths to Remember

| What | Path |
|------|------|
| Main README | `./README.md` |
| Application code | `./src/aspnet/` |
| Terraform scripts | `./src/terraform/` |
| Documentation | `./doc/` |
| Build output | `./src/aspnet/bin/` (gitignored) |
| Publish output | `./publish/` (created during build) |

## Common Tasks

### I want to...

**...run the app locally**
```bash
cd src/aspnet && dotnet run
```

**...deploy to Azure**
```bash
# See doc/DEPLOYMENT.md for full guide
cd src/terraform && terraform apply
```

**...change infrastructure**
```bash
# Edit src/terraform/variables.tf or main.tf
cd src/terraform
terraform plan  # Preview changes
terraform apply # Apply changes
```

**...add a new page**
```bash
# Add files to src/aspnet/Pages/
# Update src/aspnet/Pages/Shared/_Layout.cshtml for navigation
```

**...customize resource names**
```bash
# Edit src/terraform/variables.tf
# Or create src/terraform/terraform.tfvars
```

## Getting Help

- **Project overview**: `README.md`
- **Deployment issues**: `doc/DEPLOYMENT.md`
- **Infrastructure questions**: `src/terraform/README.md`
- **Random suffix feature**: `src/terraform/RANDOM_SUFFIX.md`
- **Project details**: `doc/PROJECT_SUMMARY.md`
