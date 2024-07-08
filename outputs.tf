output "kubectl_config" {
  description = "Command to set access to kubectl on local machine"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.tfe.name} --name ${azurerm_kubernetes_cluster.tfe.name} --overwrite-existing"
}

output "resource_group" {
  value = azurerm_resource_group.tfe.name
}

output "cluster_name" {
  value = var.environment_name
}

output "prefix" {
  value = var.environment_name
}

output "pg_dbname" {
  value = azurerm_postgresql_flexible_server_database.tfe.name
}

output "pg_user" {
  value = var.postgresql_user
}

output "pg_password" {
  value     = var.postgresql_password
  sensitive = true
}

output "pg_address" {
  value = azurerm_postgresql_flexible_server.tfe.fqdn
}

output "container_name" {
  value = azurerm_storage_container.tfe.name
}

output "storage_account" {
  value = azurerm_storage_account.tfe.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.tfe.primary_access_key
  sensitive = true
}

output "redis_host" {
  value = azurerm_redis_cache.tfe.hostname
}

output "redis_primary_access_key" {
  value     = azurerm_redis_cache.tfe.primary_access_key
  sensitive = true
}
