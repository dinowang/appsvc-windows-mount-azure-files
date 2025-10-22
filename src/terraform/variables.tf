variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-userupload"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Japan East"
}

variable "storage_account_name" {
  description = "Name of the storage account (6-char hex suffix will be appended for uniqueness)"
  type        = string
  default     = "storuserupload"
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "plan-userupload"
}

variable "app_service_name" {
  description = "Name of the App Service (6-char hex suffix will be appended for uniqueness)"
  type        = string
  default     = "web-userupload"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "production"
}
