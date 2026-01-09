# -----------------------------
# Resource Group
# -----------------------------
resource "azurerm_resource_group" "intlb_rg" {
  name     = var.resource_group_name
  location = var.location
}

# -----------------------------
# Virtual Network
# -----------------------------
resource "azurerm_virtual_network" "intlb_vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.intlb_rg.location
  resource_group_name = azurerm_resource_group.intlb_rg.name
  address_space       = var.vnet_address_space
}

# -----------------------------
# Backend Subnet
# -----------------------------
resource "azurerm_subnet" "backend" {
  name                 = "myBackendSubnet"
  resource_group_name  = azurerm_resource_group.intlb_rg.name
  virtual_network_name = azurerm_virtual_network.intlb_vnet.name
  address_prefixes     = ["10.1.0.0/24"]
}

# -----------------------------
# Frontend Subnet (for ILB)
# -----------------------------
resource "azurerm_subnet" "frontend" {
  name                 = "myFrontEndSubnet"
  resource_group_name  = azurerm_resource_group.intlb_rg.name
  virtual_network_name = azurerm_virtual_network.intlb_vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

# -----------------------------
# Azure Bastion Subnet (required name)
# -----------------------------
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.intlb_rg.name
  virtual_network_name = azurerm_virtual_network.intlb_vnet.name
  address_prefixes     = ["10.1.1.0/26"]
}
# -----------------------------
# Bastion Public IP
# -----------------------------
resource "azurerm_public_ip" "bastion_pip" {
  name                = var.bastion_pip_name
  location            = azurerm_resource_group.intlb_rg.location
  resource_group_name = azurerm_resource_group.intlb_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# -----------------------------
# Azure Bastion Host
# -----------------------------
resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion_name
  location            = azurerm_resource_group.intlb_rg.location
  resource_group_name = azurerm_resource_group.intlb_rg.name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}
# -----------------------------
# Backend Availability Set
# -----------------------------
resource "azurerm_availability_set" "backend_as" {
  name                         = "backend-avset"
  location                     = azurerm_resource_group.intlb_rg.location
  resource_group_name          = azurerm_resource_group.intlb_rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
}
# -----------------------------
# Backend NICs
# -----------------------------
resource "azurerm_network_interface" "backend_nic" {
  count               = var.vm_count
  name                = "myVMNIC${count.index + 1}"
  location            = azurerm_resource_group.intlb_rg.location
  resource_group_name = azurerm_resource_group.intlb_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}
# -----------------------------
# Backend Virtual Machines
# -----------------------------
resource "azurerm_windows_virtual_machine" "backend_vm" {
  count               = var.vm_count
  name                = "myVM${count.index + 1}"
  location            = azurerm_resource_group.intlb_rg.location
  resource_group_name = azurerm_resource_group.intlb_rg.name
  size                = var.vm_size

  admin_username = var.admin_username
  admin_password = var.admin_password

  availability_set_id = azurerm_availability_set.backend_as.id

  network_interface_ids = [
    azurerm_network_interface.backend_nic[count.index].id
  ]

  os_disk {
    name                 = "myVM${count.index + 1}-osdisk"
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
resource "azurerm_virtual_machine_extension" "backend_iis" {
  count                = length(azurerm_windows_virtual_machine.backend_vm)
  name                 = "install-iis"
  virtual_machine_id   = azurerm_windows_virtual_machine.backend_vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
{
  "commandToExecute": "powershell -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools; echo '<h1>Hello from ' $env:COMPUTERNAME '</h1>' > C:\\inetpub\\wwwroot\\index.html\""
}
SETTINGS
}
resource "azurerm_lb" "internal_lb" {
  name                = "intlb"
  location            = azurerm_resource_group.intlb_rg.location
  resource_group_name = azurerm_resource_group.intlb_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "frontend-ip"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.internal_lb.id
}
resource "azurerm_network_interface_backend_address_pool_association" "backend_pool_assoc" {
  count                   = length(azurerm_network_interface.backend_nic)
  network_interface_id    = azurerm_network_interface.backend_nic[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}
resource "azurerm_lb_probe" "http_probe" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.internal_lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}
resource "azurerm_lb_rule" "http_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.internal_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.backend_pool.id
  ]
  probe_id                = azurerm_lb_probe.http_probe.id
  idle_timeout_in_minutes = 15
  enable_floating_ip      = false
}
