output "resource_group_name" {
  value = azurerm_resource_group.intlb_rg.name
}

output "vnet_name" {
  value = azurerm_virtual_network.intlb_vnet.name
}

output "backend_subnet_id" {
  value = azurerm_subnet.backend.id
}
