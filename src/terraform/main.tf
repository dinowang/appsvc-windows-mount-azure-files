terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "azurerm" {
  tenant_id           = var.tenant_id
  subscription_id     = var.subscription_id
  use_cli             = true
  storage_use_azuread = true
  use_oidc            = true
  features {
  }
}

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  suffix        = random_id.suffix.hex
  aspnet_path   = "${path.module}/../aspnet"
  publish_path  = "${path.module}/../../publish"
  zip_file_path = "${path.module}/../../app.zip"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${local.suffix}"
  location = var.location
}

resource "azurerm_storage_account" "storage" {
  name                     = "${var.storage_account_name}${local.suffix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Temporarily enable shared key access for Terraform to create resources
  # Will be disabled via null_resource after file share is created
  shared_access_key_enabled       = true
  default_to_oauth_authentication = true

  # Allow Azure Services to access (needed for App Service)
  public_network_access_enabled = true

  tags = {
    environment = var.environment
  }
}

resource "azurerm_storage_share" "fileshare" {
  name                 = "userupload-files"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 50
}

# Disable shared key access after file share is created
resource "null_resource" "disable_shared_key" {
  triggers = {
    storage_account = azurerm_storage_account.storage.id
    file_share      = azurerm_storage_share.fileshare.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      az storage account update \
        --name ${azurerm_storage_account.storage.name} \
        --resource-group ${azurerm_resource_group.rg.name} \
        --allow-shared-key-access false
    EOT
  }

  depends_on = [
    azurerm_storage_share.fileshare
  ]
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.app_service_plan_name}-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "B1" # Basic tier - for dev/test. Change to P0v3 for production.

  tags = {
    environment = var.environment
  }
}

resource "azurerm_windows_web_app" "app" {
  name                = "${var.app_service_name}-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true

    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v8.0"
    }
  }

  app_settings = {
    "WEBSITE_MOUNT_ENABLED" = "1"
  }

  tags = {
    environment = var.environment
  }

  # zip_deploy_file = local.zip_file_path

  # depends_on = [
  #   data.archive_file.app_zip
  # ]
}

# Configure Azure Files mount using managed identity via Azure REST API
# The azurerm provider doesn't yet support managed identity for storage mounts
resource "null_resource" "configure_storage_mount" {
  triggers = {
    app_id          = azurerm_windows_web_app.app.id
    storage_account = azurerm_storage_account.storage.name
    file_share      = azurerm_storage_share.fileshare.name
    role_assignment = azurerm_role_assignment.app_storage_file_data_privileged_contributor.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for role assignment propagation
      sleep 30
      
      # Configure storage mount with managed identity
      az rest --method PUT \
        --uri "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Web/sites/${azurerm_windows_web_app.app.name}/config/azureStorageAccounts/useruploadfiles?api-version=2022-03-01" \
        --body '{
          "properties": {
            "type": "AzureFiles",
            "accountName": "${azurerm_storage_account.storage.name}",
            "shareName": "${azurerm_storage_share.fileshare.name}",
            "mountPath": "/mounts/uploads",
            "protocol": "SMB",
            "accessKey": ""
          }
        }'
    EOT
  }

  depends_on = [
    azurerm_windows_web_app.app,
    azurerm_role_assignment.app_storage_file_data_privileged_contributor,
    azurerm_role_assignment.app_storage_account_contributor
  ]
}

# Build the ASP.NET application
resource "null_resource" "build_app" {
  triggers = {
    # Rebuild when source files change
    source_hash = filemd5("${local.aspnet_path}/Program.cs")
  }

  provisioner "local-exec" {
    command     = "dotnet publish -c Release -o ${local.publish_path}"
    working_dir = local.aspnet_path
  }
}

# Create zip archive from published application
data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = local.publish_path
  output_path = local.zip_file_path

  depends_on = [
    null_resource.build_app
  ]
}

# Grant App Service managed identity access to Storage Account
# Storage File Data Privileged Contributor role for mounting Azure Files
resource "azurerm_role_assignment" "app_storage_file_data_privileged_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_windows_web_app.app.identity[0].principal_id
}

# Additional role assignment for Storage Blob Data Contributor (if needed for blob access)
resource "azurerm_role_assignment" "app_storage_account_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_windows_web_app.app.identity[0].principal_id
}
