# 1. Create a Public IP for the Bastion
resource "azurerm_public_ip" "bastion_ip" {
  name = "bastion-public-ip"
  location = var.REGION
  resource_group_name = azurerm_resource_group.serverless_rg.name
  allocation_method = "Static"
  sku = "Standard"
}

# 2. Create the Network Interface in the bastion_subnet
resource "azurerm_network_interface" "bastion_nic" {
  name = "bastion-nic"
  location = var.REGION
  resource_group_name = azurerm_resource_group.serverless_rg.name

  ip_configuration {
    name = "internal"
    # Points to your specific bastion_subnet
    subnet_id = module.serverless_vnet.subnets["bastion_subnet"].resource_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}

# 3. Associate the NSG with the Bastion NIC
# This ensures your SSH rules are enforced
resource "azurerm_network_interface_security_group_association" "bastion_nsg_assoc" {
  network_interface_id = azurerm_network_interface.bastion_nic.id
  network_security_group_id = module.nsg_private_subnet.resource_id
}

# 4. Create the Linux Virtual Machine
# psql -h item-catalog-db.postgres.database.azure.com -U psqladmin -d postgres
resource "azurerm_linux_virtual_machine" "bastion_host" {
  name = "bastion-host"
  location = var.REGION
  resource_group_name = azurerm_resource_group.serverless_rg.name
  size = "Standard_D2s_v3"
  admin_username = "ubuntu"

  network_interface_ids = [azurerm_network_interface.bastion_nic.id]

  admin_ssh_key {
    username = "ubuntu"
    public_key = file("./key/azure_rsa.pub")
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "0001-com-ubuntu-server-jammy"
    sku = "22_04-lts"
    version = "latest"
  }

  user_data = base64encode(<<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y postgresql-client nmap
  EOT
  )

  tags = {
    Environment = var.ENV
  }
}