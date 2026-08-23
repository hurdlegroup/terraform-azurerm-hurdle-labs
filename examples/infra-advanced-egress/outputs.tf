// These outputs intentionally re-export the child module API; child-module resources and locals are scope-isolated.
output "resource_group_name" {
  description = "Name of the deployed Azure resource group."
  value       = module.hurdle_labs_infra.resource_group_name
}

output "resource_group_id" {
  description = "ID of the deployed Azure resource group."
  value       = module.hurdle_labs_infra.resource_group_id
}

output "vnet_id" {
  description = "ID of the deployed virtual network."
  value       = module.hurdle_labs_infra.vnet_id
}

output "bridge_subnet_id" {
  description = "ID of the bridge subnet."
  value       = module.hurdle_labs_infra.bridge_subnet_id
}

output "machines_subnet_id" {
  description = "ID of the machines subnet used for ephemeral lab VMs."
  value       = module.hurdle_labs_infra.machines_subnet_id
}

output "machines_nat_gateway_id" {
  description = "ID of the machines subnet NAT gateway."
  value       = module.hurdle_labs_infra.machines_nat_gateway_id
}

output "machines_egress_mode" {
  description = "Effective egress mode for lab machines subnet."
  value       = module.hurdle_labs_infra.machines_egress_mode
}

output "machines_route_table_id" {
  description = "Route table ID associated with machines subnet when firewall egress is enabled."
  value       = module.hurdle_labs_infra.machines_route_table_id
}

output "machines_managed_firewall_id" {
  description = "ID of managed Azure Firewall when machines_egress_mode is firewall_module_provisioned."
  value       = module.hurdle_labs_infra.machines_managed_firewall_id
}

output "machines_managed_firewall_private_ip" {
  description = "Private IP of managed Azure Firewall when machines_egress_mode is firewall_module_provisioned."
  value       = module.hurdle_labs_infra.machines_managed_firewall_private_ip
}

output "bridge_ingress_mode" {
  description = "Effective ingress mode for bridge traffic."
  value       = module.hurdle_labs_infra.bridge_ingress_mode
}

output "bridge_appgw_id" {
  description = "ID of managed Application Gateway when bridge_ingress_mode is appgw_waf."
  value       = module.hurdle_labs_infra.bridge_appgw_id
}

output "bridge_appgw_public_ip" {
  description = "Public IPv4 address of managed Application Gateway when bridge_ingress_mode is appgw_waf."
  value       = module.hurdle_labs_infra.bridge_appgw_public_ip
}

output "bridge_appgw_public_fqdn" {
  description = "Public DNS FQDN of managed Application Gateway when bridge_ingress_mode is appgw_waf."
  value       = module.hurdle_labs_infra.bridge_appgw_public_fqdn
}

output "bridge_appgw_waf_policy_id" {
  description = "WAF policy ID attached to managed Application Gateway when bridge_ingress_mode is appgw_waf."
  value       = module.hurdle_labs_infra.bridge_appgw_waf_policy_id
}

output "bridge_vm_id" {
  description = "ID of the persistent bridge VM."
  value       = module.hurdle_labs_infra.bridge_vm_id
}

output "bridge_vm_name" {
  description = "Name of the persistent bridge VM."
  value       = module.hurdle_labs_infra.bridge_vm_name
}

output "bridge_public_ip_address" {
  description = "Public IPv4 address assigned to the bridge VM."
  value       = module.hurdle_labs_infra.bridge_public_ip_address
}

output "bridge_public_fqdn" {
  description = "Public bridge endpoint FQDN."
  value       = module.hurdle_labs_infra.bridge_public_fqdn
}

output "bridge_nsg_id" {
  description = "ID of the bridge Network Security Group."
  value       = module.hurdle_labs_infra.bridge_nsg_id
}

output "bridge_nsg_name" {
  description = "Name of the bridge Network Security Group."
  value       = module.hurdle_labs_infra.bridge_nsg_name
}
