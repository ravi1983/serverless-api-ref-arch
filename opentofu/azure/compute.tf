# Container for the function code
resource "azurerm_storage_account" "cart_func_code" {
  name = "cartfunccode2026"
  resource_group_name = azurerm_resource_group.serverless_rg.name
  location = var.REGION
  account_tier = "Standard"
  account_replication_type = "LRS"

  tags = {
    End = var.ENV
  }
}

resource "azurerm_storage_container" "func_releases" {
  name = "function-releases"
  storage_account_id = azurerm_storage_account.cart_func_code.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "func_plan" {
  name = "cart-flex-plan"
  resource_group_name = azurerm_resource_group.serverless_rg.name
  location = var.REGION
  os_type = "Linux"
  sku_name = "FC1" # Flex Consumption SKU
}

# Create a Linux Function App with Flex Consumption Plan
resource "azurerm_function_app_flex_consumption" "cart_function" {
  name = "cart-function"
  resource_group_name = azurerm_resource_group.serverless_rg.name
  location = var.REGION
  service_plan_id = azurerm_service_plan.func_plan.id

  # Storage Configuration for Flex
  storage_container_type = "blobContainer"
  storage_container_endpoint = "${azurerm_storage_account.cart_func_code.primary_blob_endpoint}${azurerm_storage_container.func_releases.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key = azurerm_storage_account.cart_func_code.primary_access_key

  # Runtime and Scale Configuration
  runtime_name = "python" # Changed from your example to match your Python 3.12 requirement
  runtime_version = "3.12"
  maximum_instance_count = 40
  instance_memory_in_mb = 2048

  # Networking
  virtual_network_subnet_id = module.serverless_vnet.subnets["function_subnet"].resource_id

  site_config {
    vnet_route_all_enabled = true
  }

  app_settings = {
    "CLOUD_RUNTIME" = "AZURE"
    "CART_TABLE_NAME" = azurerm_cosmosdb_sql_container.cart.name

    # DB Details
    "DATABASE_URL" = azurerm_postgresql_flexible_server.postgres.fqdn
    "DB_USER" = azurerm_postgresql_flexible_server.postgres.administrator_login
    "DB_PASSWORD" = var.DB_PASSWORD

    # Cosmos Details
    "COSMOS_ENDPOINT" = azurerm_cosmosdb_account.cosmos.endpoint
    "COSMOS_KEY" = azurerm_cosmosdb_account.cosmos.primary_key
    "COSMOS_DATABASE" = azurerm_cosmosdb_sql_database.db.name
  }
}

# API management for the function
# resource "azurerm_api_management" "apim" {
#   name = "cart-api-management"
#   location = var.REGION
#   resource_group_name = azurerm_resource_group.serverless_rg.name
#
#   publisher_name = "Valluvam"
#   publisher_email = "admin@valluvam.com"
#   sku_name = "Consumption_0"
# }
#
# # Create the API definition
# resource "azurerm_api_management_api" "cart_api" {
#   name = "cart-api"
#   resource_group_name = azurerm_resource_group.serverless_rg.name
#   api_management_name = azurerm_api_management.apim.name
#   revision = "1"
#   display_name = "Cart Service API"
#   path = "v1"
#   protocols = ["https"]
#   service_url = "https://${azurerm_function_app_flex_consumption.cart_function.default_hostname}/api"
# }
#
# # Link the Function as a Backend for better routing/metrics
# resource "azurerm_api_management_backend" "func_backend" {
#   name = "cart-backend"
#   resource_group_name = azurerm_resource_group.serverless_rg.name
#   api_management_name = azurerm_api_management.apim.name
#   protocol = "http"
#   url = "https://${azurerm_function_app_flex_consumption.cart_function.default_hostname}/api"
#
#   credentials {
#     header = {
#       "x-functions-key" = "{{function-key-secret}}" # Best practice: Use a Named Value/Key Vault
#     }
#   }
# }