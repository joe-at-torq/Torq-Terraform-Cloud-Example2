
#Azure Provider
provider "azurerm" {
  features {}
  skip_provider_registration = true

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

#Deployment Variables
#----------------------------------------------------------------------------------

variable "client_side_region" {
  type = string
  default  = "eastus"
}

#Resouce Group
resource "azurerm_resource_group" "client_rg" {
  name     = "Torq_Terraform_Cloud2"
  location = var.client_side_region
}

#Network
resource "azurerm_virtual_network" "client_rg_network" {
  name                = "client_network"
  resource_group_name = azurerm_resource_group.client_rg.name
  location            = azurerm_resource_group.client_rg.location
  address_space       = ["10.0.0.0/16"]
}

#Edge Subnet
resource "azurerm_subnet" "client_rg_edge_subnet" {
  name                 = "edge_subnet"
  resource_group_name  = azurerm_resource_group.client_rg.name
  virtual_network_name = azurerm_virtual_network.client_rg_network.name
  address_prefixes       = ["10.0.5.0/24"]
}

#User Subnet
resource "azurerm_subnet" "client_rg_user_subnet" {
  name                 = "user_subnet"
  resource_group_name  = azurerm_resource_group.client_rg.name
  virtual_network_name = azurerm_virtual_network.client_rg_network.name
  address_prefixes       = ["10.0.10.0/24"]
}

#Windows Client Public Ip
resource "azurerm_public_ip" "cgc_windows_client_pip" {
    name                  = "WindowsClientPublicIP"
    location              = azurerm_resource_group.client_rg.location
    resource_group_name   = azurerm_resource_group.client_rg.name
    allocation_method     = "Dynamic"
}

#Windows Host Nic
resource "azurerm_network_interface" "cgc_windows_client_nic" {
    name                = "myNIC"
    location              = azurerm_resource_group.client_rg.location
    resource_group_name   = azurerm_resource_group.client_rg.name

    ip_configuration {
      name                          = "WindowsclientNicConfiguration"
      subnet_id                     = azurerm_subnet.client_rg_user_subnet.id
      private_ip_address_allocation = "Static"
      private_ip_address            = "10.0.10.20"
      public_ip_address_id          = azurerm_public_ip.cgc_windows_client_pip.id
    }
}

#Windows Client
resource "azurerm_virtual_machine" "cgc_windows_client_vm" {
  name                  = "WindowsClient"
  location              = azurerm_resource_group.client_rg.location
  resource_group_name   = azurerm_resource_group.client_rg.name
  vm_size               = "Standard_B2ms"
  network_interface_ids = ["${azurerm_network_interface.cgc_windows_client_nic.id}"]
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-21h2-pro"
    version   = "latest"
  }

  storage_os_disk {
    name          = "windowsclient-osdisk1"
    caching       = "ReadWrite"
    create_option = "FromImage"
    os_type       = "Windows"
  }

  os_profile {
    computer_name  = "WindowsClient"
    admin_username = "client"
    admin_password = "1qaz!QAZ1qaz!QAZ"
  }

  os_profile_windows_config {
  }
}
