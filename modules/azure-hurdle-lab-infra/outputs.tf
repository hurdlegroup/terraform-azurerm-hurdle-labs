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
  value       = local.is_nat_mode ? azurerm_nat_gateway.machines[0].id : null
}

output "machines_egress_mode" {
  description = "Effective egress mode for lab machines subnet."
  value       = var.machines_egress_mode
}

output "machines_route_table_id" {
  description = "Route table ID associated with machines subnet when firewall egress is enabled."
  value       = local.is_nat_mode ? null : (local.use_byo_route_table ? data.azurerm_route_table.byo[0].id : azurerm_route_table.machines_egress[0].id)
}

output "machines_managed_firewall_id" {
  description = "ID of managed Azure Firewall when machines_egress_mode is firewall_module_provisioned."
  value       = local.is_managed_firewall_mode ? azurerm_firewall.managed[0].id : null
}

output "machines_managed_firewall_private_ip" {
  description = "Private IP of managed Azure Firewall when machines_egress_mode is firewall_module_provisioned."
  value       = local.is_managed_firewall_mode ? azurerm_firewall.managed[0].ip_configuration[0].private_ip_address : null
}

output "bridge_ingress_mode" {
  description = "Effective ingress mode for bridge traffic."
  value       = var.bridge_ingress_mode
}

output "bridge_appgw_id" {
  description = "ID of managed Application Gateway when bridge_ingress_mode is appgw_waf."
  value       = local.is_appgw_ingress_mode ? azurerm_application_gateway.bridge[0].id : null
}

output "bridge_appgw_public_ip" {
  description = "Public IPv4 address of managed Application Gateway when bridge_ingress_mode is appgw_waf."
  value       = local.is_appgw_ingress_mode ? azurerm_public_ip.bridge_appgw[0].ip_address : null
}

output "bridge_appgw_public_fqdn" {
  description = "Public DNS FQDN of managed Application Gateway when bridge_ingress_mode is appgw_waf."
  value       = local.is_appgw_ingress_mode ? azurerm_public_ip.bridge_appgw[0].fqdn : null
}

output "bridge_appgw_waf_policy_id" {
  description = "WAF policy ID attached to managed Application Gateway when bridge_ingress_mode is appgw_waf."
  value       = local.is_appgw_ingress_mode ? azurerm_web_application_firewall_policy.bridge[0].id : null
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
  description = "Public bridge endpoint FQDN (bridge PIP in direct mode, App Gateway FQDN in appgw_waf mode)."
  value       = local.bridge_public_fqdn
}

output "bridge_nsg_id" {
  description = "ID of the bridge Network Security Group."
  value       = azurerm_network_security_group.bridge.id
}

output "bridge_nsg_name" {
  description = "Name of the bridge Network Security Group."
  value       = azurerm_network_security_group.bridge.name
}
