output "resource_group_name" {
  description = "Name of the deployed Azure resource group."
  value       = azurerm_resource_group.hurdle_lab.name
}

output "resource_group_id" {
  description = "ID of the deployed Azure resource group."
  value       = azurerm_resource_group.hurdle_lab.id
}

output "vnet_id" {
  description = "ID of the deployed virtual network."
  value       = azurerm_virtual_network.hurdle_lab.id
}

output "bridge_subnet_id" {
  description = "ID of the bridge subnet."
  value       = azurerm_subnet.bridge.id
}

output "machines_subnet_id" {
  description = "ID of the machines subnet used for ephemeral lab VMs."
  value       = azurerm_subnet.machines.id
}

output "machines_nat_gateway_id" {
  description = "ID of the machines subnet NAT gateway."
  value       = azurerm_nat_gateway.machines.id
}

output "bridge_vm_id" {
  description = "ID of the persistent bridge VM."
  value       = azurerm_linux_virtual_machine.bridge.id
}

output "bridge_vm_name" {
  description = "Name of the persistent bridge VM."
  value       = azurerm_linux_virtual_machine.bridge.name
}

output "bridge_public_ip_address" {
  description = "Public IPv4 address assigned to the bridge VM."
  value       = azurerm_public_ip.bridge.ip_address
}

output "bridge_public_fqdn" {
  description = "Public DNS FQDN assigned to the bridge VM public IP."
  value       = azurerm_public_ip.bridge.fqdn
}

output "bridge_nsg_id" {
  description = "ID of the bridge Network Security Group."
  value       = azurerm_network_security_group.bridge.id
}

output "bridge_nsg_name" {
  description = "Name of the bridge Network Security Group."
  value       = azurerm_network_security_group.bridge.name
}
