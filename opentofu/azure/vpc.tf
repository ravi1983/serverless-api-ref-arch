# Create resource group
resource "azurerm_resource_group" "serverless_rg" {
  name = "serverless_rg"
  location = var.REGION

  tags = {
    environment = var.ENV
  }
}

# Create virtual network with one private subnet
module "serverless_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"

  name = "serverless_vnet"
  parent_id = azurerm_resource_group.serverless_rg.id
  location = var.REGION
  address_space = ["10.0.0.0/16"]

  subnets = {
    function_subnet = {
      name = "function_subnet"
      address_prefixes = ["10.0.1.0/24"]
      default_outbound_access_enabled = false

      nat_gateway = {
        id = module.nat_gateway.resource_id
      }
      network_security_group = {
        id = module.nsg_private_subnet.resource_id
      }

      delegations = [{
        name = "function-app-delegation"
        service_delegation = {
          name = "Microsoft.App/environments"
        }
      }]
    },
    db_subnet = {
      name = "db_subnet"
      address_prefixes = ["10.0.2.0/24"]
      default_outbound_access_enabled = false

      nat_gateway = {
        id = module.nat_gateway.resource_id
      }
      network_security_group = {
        id = module.nsg_private_subnet.resource_id
      }
    },
    private_endpoint_subnet = {
      name = "private_endpoint_subnet"
      address_prefixes = ["10.0.3.0/24"]
      default_outbound_access_enabled = false
    }
  }
}

# Create NAT gateway
module "nat_gateway" {
  source = "Azure/avm-res-network-natgateway/azurerm"

  name = "nat_gateway"
  location = var.REGION
  resource_group_name = azurerm_resource_group.serverless_rg.name

  public_ips = {
    primary = {
      name = "nat_gw_pip_1"
    }
  }
}

# Create Network Security Group
module "nsg_private_subnet" {
  source = "Azure/avm-res-network-networksecuritygroup/azurerm"

  name = "nsg_private_subnet"
  location = var.REGION
  resource_group_name = azurerm_resource_group.serverless_rg.name

  security_rules = {
    "AllowVnetInbound" = {
      name = "AllowVnetInbound"
      priority = 100
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "*"
      source_address_prefix = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    "AllowPostgresInbound" = {
      name                       = "AllowPostgresInbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      # Can also do VirtualNetwork
      source_address_prefix      = "10.0.1.0/24"
      destination_address_prefix = "10.0.3.0/24"
    }
  }
}
