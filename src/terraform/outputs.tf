output "naming_suffix" {
  description = "Random suffix used for all resources"
  value       = local.suffix
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = "https://${azurerm_windows_web_app.app.default_hostname}"
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.storage.name
}

output "file_share_name" {
  description = "Name of the Azure File Share"
  value       = azurerm_storage_share.fileshare.name
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.plan.name
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_windows_web_app.app.name
}

output "deployment_package" {
  description = "Path to the deployment zip file"
  value       = local.zip_file_path
}
