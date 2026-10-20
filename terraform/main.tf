locals {
  name = var.project_name
  tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
    Owner     = "Muhammad Ahmad"
  }
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  name     = "${local.name}-rg"
  location = var.location
  tags     = local.tags
}

############################
# Storage (Functions runtime)
############################
resource "azurerm_storage_account" "this" {
  name                     = "${replace(var.project_name, "-", "")}st${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_service_plan" "this" {
  name                = "${local.name}-plan"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption
  tags                = local.tags
}

############################
# Cosmos DB (SQL API)
############################
resource "azurerm_cosmosdb_account" "this" {
  name                = "${local.name}-cosmos-${random_string.suffix.result}"
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

  tags = local.tags
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
# Function App (Linux, consumption)
############################
resource "azurerm_linux_function_app" "this" {
  name                = "${local.name}-app-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key

  site_config {
    application_stack {
      node_version = "20"
    }
  }

  app_settings = {
    COSMOS_ENDPOINT = azurerm_cosmosdb_account.this.endpoint
    COSMOS_DATABASE = azurerm_cosmosdb_sql_database.this.name
  }

  tags = local.tags
}
