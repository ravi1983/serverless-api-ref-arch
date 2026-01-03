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
    },
    bastion_subnet = {
      name = "bastion_subnet"
      address_prefixes = ["10.0.4.0/24"]
      default_outbound_access_enabled = true
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
    # 1. Allow SSH into the Bastion Host from your local IP
    "AllowBastionSSH" = {
      name = "AllowBastionSSH"
      priority = 130
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "22"
      source_address_prefix = var.MY_IP
      destination_address_prefix = "10.0.4.0/24" # Targeting the Bastion Subnet
    },

    # 2. Allow Function App testing from your local IP (HTTPS)
    "AllowMyIPInbound" = {
      name = "AllowMyIPInbound"
      priority = 140
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "443"
      source_address_prefix = var.MY_IP
      destination_address_prefix = "*"
    },

    # 3. Allow Internal VNet traffic
    "AllowVnetInbound" = {
      name = "AllowVnetInbound"
      priority = 150
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "*"
      source_address_prefix = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },

    # 4. Allow Postgres traffic from both the Function Subnet AND the Bastion Subnet
    "AllowPostgresInbound" = {
      name = "AllowPostgresInbound"
      priority = 160
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "5432"
      # Combined range covering 10.0.1.0 (Functions) and 10.0.4.0 (Bastion)
      # Or you can use "VirtualNetwork" as the source for simplicity
      source_address_prefix = "VirtualNetwork"
      destination_address_prefix = "10.0.3.0/24" # The Postgres Subnet
    }
  }
}
