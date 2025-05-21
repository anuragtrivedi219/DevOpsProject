# Adding provider details

terraform{
  required_providers{
    azurerm= {
      source="hashicorp/azurerm"
      version="3.20.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = var.subnet1_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet1_prefix]
}

resource "azurerm_subnet" "subnet2" {
  name                 = var.subnet2_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet2_prefix]
}

resource "azurerm_availability_set" "avset_vm01" {
  name                         = "avset-vm01"
  location                     = var.location
  resource_group_name = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
}

resource "azurerm_availability_set" "avset_vm02" {
  name                         = "avset-vm02"
  location                     = var.location
  resource_group_name = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
}

resource "azurerm_public_ip" "pip_vm01" {
  name                = "pip-vm01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_security_group" "nsg_vm01" {
  name                = "nsg-vm01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = var.rdp_allowed_ip
    destination_port_range     = "3389"
    destination_address_prefix = "*"
    source_port_range          = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_port_range     = "80"
    destination_address_prefix = "*"
    source_port_range          = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_port_range     = "443"
    destination_address_prefix = "*"
    source_port_range          = "*"
  }
}

resource "azurerm_network_security_group" "nsg_vm02" {
  name                = "nsg-vm02"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = var.vm01_private_ip
    destination_port_range     = "1433"
    destination_address_prefix = "*"
    source_port_range          = "*"
  }

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = var.rdp_allowed_ip
    destination_port_range     = "3389"
    destination_address_prefix = "*"
    source_port_range          = "*"
  }
}

resource "azurerm_network_interface" "nic_vm01" {
  name                = "nic-vm01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm01_private_ip
    public_ip_address_id          = azurerm_public_ip.pip_vm01.id
  }
}

resource "azurerm_network_interface" "nic_vm02" {
  name                = "nic-vm02"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm02_private_ip
  }
}

# NSG associations (NIC level)
resource "azurerm_network_interface_security_group_association" "nsg_nic_vm01" {
  network_interface_id      = azurerm_network_interface.nic_vm01.id
  network_security_group_id = azurerm_network_security_group.nsg_vm01.id
}

resource "azurerm_network_interface_security_group_association" "nsg_nic_vm02" {
  network_interface_id      = azurerm_network_interface.nic_vm02.id
  network_security_group_id = azurerm_network_security_group.nsg_vm02.id
}

resource "azurerm_windows_virtual_machine" "vm01" {
  name                  = "vm01"
  location              = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic_vm01.id]
  availability_set_id   = azurerm_availability_set.avset_vm01.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
  resource "azurerm_virtual_machine_extension" "vm01" {
  name                 = "dsc-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm01.id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.76"

  settings = jsonencode({
    ModulesUrl            = "https://anuragterraformremobcknd.blob.core.windows.net/dsc-scripts/ConfigureWebServer.zip?sp=racwdli&st=2025-05-21T07:32:04Z&se=2025-05-21T15:32:04Z&sv=2024-11-04&sr=c&sig=3lXLz5V2KfxLBYgCCg6LfM50yZ6uX5%2Br%2BTyYs3LgW4Q%3D"
    ConfigurationFunction = "ConfigureWebServer.ps1\\ConfigureWebServer"
  })
}

resource "azurerm_windows_virtual_machine" "vm02" {
  name                  = "vm02"
  location              = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic_vm02.id]
  availability_set_id   = azurerm_availability_set.avset_vm02.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

 source_image_reference {
  publisher = "MicrosoftSQLServer"
  offer     = "sql2019-ws2019"
  sku       = "sqldev"
  version   = "latest"
  }
}

terraform {
  backend "azurerm" {
    resource_group_name   = "Anurag-RG"
    storage_account_name  = "anuragterraformremobcknd"
    container_name        = "terraformremobcknd219-container"
    key                   = "terraform.tfstate"
  }
}
