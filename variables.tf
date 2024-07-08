variable "environment_name" {
  type        = string
  description = "Name used to create and tag resources"
}

variable "region" {
  type        = string
  description = "Azure region to deploy in"
}

variable "vnet_cidr" {
  type        = string
  description = "The IP range for the VNet in CIDR format"
}

variable "postgresql_user" {
  description = "PostgreSQL user"
  type        = string
}

variable "postgresql_password" {
  description = "PostgreSQL password"
  type        = string
}

variable "storage_name" {
  type        = string
  description = "Name used to create storage account. Can contain ONLY lowercase letters and numbers; must be unique across all existing storage account names in Azure"
}