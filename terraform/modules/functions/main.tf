resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-rg"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name_prefix}-law"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "this" {
  name                = "${var.name_prefix}-ai"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
}

resource "azurerm_storage_account" "this" {
  name                            = "${replace(var.name_prefix, "-", "")}st${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
}

resource "azurerm_service_plan" "this" {
  name                = "${var.name_prefix}-plan"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

############################
# Cosmos DB
############################
resource "azurerm_cosmosdb_account" "this" {
  name                = "${var.name_prefix}-cosmos-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }
  geo_location {
    location          = var.location
    failover_priority = 0
  }
  backup {
    type                = "Periodic"
    interval_in_minutes = 240
    retention_in_hours  = 8
    storage_redundancy  = "Local"
  }
}

resource "azurerm_cosmosdb_sql_database" "this" {
  name                = "appdb"
  resource_group_name = azurerm_resource_group.this.name
  account_name        = azurerm_cosmosdb_account.this.name
}

resource "azurerm_cosmosdb_sql_container" "this" {
  name                  = "items"
  resource_group_name   = azurerm_resource_group.this.name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.this.name
  partition_key_paths   = ["/id"]
  partition_key_version = 2
}

############################
# Function App
############################
resource "azurerm_linux_function_app" "this" {
  name                = "${var.name_prefix}-app-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version                    = "1.2"
    ftps_state                             = "Disabled"
    application_insights_connection_string = azurerm_application_insights.this.connection_string
    application_stack {
      node_version = "20"
    }
  }

  app_settings = {
    COSMOS_ENDPOINT = azurerm_cosmosdb_account.this.endpoint
    COSMOS_DATABASE = azurerm_cosmosdb_sql_database.this.name
  }
}
