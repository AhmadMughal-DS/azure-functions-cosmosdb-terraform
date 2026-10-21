output "function_app_hostname" {
  value = azurerm_linux_function_app.this.default_hostname
}
output "cosmos_endpoint" {
  value = azurerm_cosmosdb_account.this.endpoint
}
output "resource_group" {
  value = azurerm_resource_group.this.name
}
