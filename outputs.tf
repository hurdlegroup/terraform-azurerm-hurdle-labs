output "app_registration_client_id" {
  value = module.azure_hurdle_lab_identity.app_registration_client_id
}

output "service_principal_object_id" {
  value = module.azure_hurdle_lab_identity.service_principal_object_id
}

output "app_registration_client_secret_value" {
  value     = module.azure_hurdle_lab_identity.app_registration_client_secret_value
  sensitive = true
}

output "app_registration_client_secret_name" {
  value = module.azure_hurdle_lab_identity.app_registration_client_secret_name
}

output "app_registration_client_secret_id" {
  value = module.azure_hurdle_lab_identity.app_registration_client_secret_id
}

output "resource_group_name" {
  value = module.azure_hurdle_lab_infra.resource_group_name
}

output "resource_group_id" {
  value = module.azure_hurdle_lab_infra.resource_group_id
}

output "vnet_id" {
  value = module.azure_hurdle_lab_infra.vnet_id
}

output "bridge_subnet_id" {
  value = module.azure_hurdle_lab_infra.bridge_subnet_id
}

output "machines_subnet_id" {
  value = module.azure_hurdle_lab_infra.machines_subnet_id
}

output "machines_nat_gateway_id" {
  value = module.azure_hurdle_lab_infra.machines_nat_gateway_id
}

output "bridge_vm_id" {
  value = module.azure_hurdle_lab_infra.bridge_vm_id
}

output "bridge_vm_name" {
  value = module.azure_hurdle_lab_infra.bridge_vm_name
}

output "bridge_admin_username" {
  value = var.bridge_admin_username
}

output "bridge_public_ip_address" {
  value = module.azure_hurdle_lab_infra.bridge_public_ip_address
}

output "bridge_public_fqdn" {
  value = module.azure_hurdle_lab_infra.bridge_public_fqdn
}

output "bridge_nsg_id" {
  value = module.azure_hurdle_lab_infra.bridge_nsg_id
}

output "bridge_nsg_name" {
  value = module.azure_hurdle_lab_infra.bridge_nsg_name
}
