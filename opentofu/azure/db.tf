# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  name = "item-catalog-db"
  location = var.REGION
  resource_group_name = azurerm_resource_group.serverless_rg.name

  version = "14"
  sku_name = "B_Standard_B1ms"
  storage_mb = 32768

  administrator_login = "psqladmin"
  administrator_password = var.DB_PASSWORD
  public_network_access_enabled = false

  lifecycle {
    ignore_changes = [
      zone
    ]
  }
}

# Private Endpoint (The 'NIC' for your database)
resource "azurerm_private_endpoint" "pg_endpoint" {
  name = "pg-private-endpoint"
  location = var.REGION
  resource_group_name = azurerm_resource_group.serverless_rg.name
  subnet_id = module.serverless_vnet.subnets["private_endpoint_subnet"].resource_id

  private_service_connection {
    name = "pg-privatelink-conn"
    private_connection_resource_id = azurerm_postgresql_flexible_server.postgres.id
    subresource_names = ["postgresqlServer"]
    is_manual_connection = false
  }

  private_dns_zone_group {
    name = "pg-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.pg_dns.id]
  }
}

resource "azurerm_private_dns_zone" "pg_dns" {
  name = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.serverless_rg.name
}

# Link DNS to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "pg_dns_link" {
  name = "pg-dns-link"
  resource_group_name = azurerm_resource_group.serverless_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pg_dns.name
  virtual_network_id = module.serverless_vnet.resource_id
}

# CosmosDB
resource "azurerm_cosmosdb_account" "cosmos" {
  name = "cart-account"
  location = var.REGION
  resource_group_name = azurerm_resource_group.serverless_rg.name
  offer_type = "Standard"
  kind = "GlobalDocumentDB"

  capabilities {
    name = "EnableServerless"
  }

  public_network_access_enabled = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location = var.REGION
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name = "cartdb"
  resource_group_name = azurerm_resource_group.serverless_rg.name
  account_name = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "cart" {
  name = "cart"
  resource_group_name = azurerm_resource_group.serverless_rg.name
  account_name = azurerm_cosmosdb_account.cosmos.name
  database_name = azurerm_cosmosdb_sql_database.db.name
  partition_key_paths = ["/userId"]
  partition_key_version = 2
}