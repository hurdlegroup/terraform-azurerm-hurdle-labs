output "resource_group_name" {
  description = "Resource group name."
  value       = azurerm_resource_group.hurdle_lab.name
}

output "resource_group_id" {
  description = "Resource group ID."
  value       = azurerm_resource_group.hurdle_lab.id
}

output "vnet_id" {
  description = "Virtual network ID."
  value       = azurerm_virtual_network.hurdle_lab.id
}

output "bridge_subnet_id" {
  description = "Bridge subnet ID."
  value       = azurerm_subnet.bridge.id
}

output "machines_subnet_id" {
  description = "Machines subnet ID."
  value       = azurerm_subnet.machines.id
}

output "machines_nat_gateway_id" {
  description = "Machines NAT gateway ID."
  value       = azurerm_nat_gateway.machines.id
}

output "bridge_vm_id" {
  description = "Bridge VM ID."
  value       = azurerm_linux_virtual_machine.bridge.id
}

output "bridge_vm_name" {
  description = "Bridge VM name."
  value       = azurerm_linux_virtual_machine.bridge.name
}

output "bridge_public_ip_address" {
  description = "Bridge VM public IP address."
  value       = azurerm_public_ip.bridge.ip_address
}

output "bridge_public_fqdn" {
  description = "Bridge VM public DNS FQDN."
  value       = azurerm_public_ip.bridge.fqdn
}

output "bridge_nsg_id" {
  description = "Bridge NSG ID."
  value       = azurerm_network_security_group.bridge.id
}

output "bridge_nsg_name" {
  description = "Bridge NSG name."
  value       = azurerm_network_security_group.bridge.name
}
