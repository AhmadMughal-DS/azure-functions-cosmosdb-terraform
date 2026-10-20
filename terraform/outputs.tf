output "function_app_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_linux_function_app.this.default_hostname
}

output "cosmos_endpoint" {
  description = "Cosmos DB account endpoint"
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "resource_group" {
  description = "Resource group name"
  value       = azurerm_resource_group.this.name
}
