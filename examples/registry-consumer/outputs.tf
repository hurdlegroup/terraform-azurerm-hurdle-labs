output "app_registration_client_id" {
  value = module.hurdle_labs.app_registration_client_id
}

output "app_registration_client_secret_name" {
  value = module.hurdle_labs.app_registration_client_secret_name
}

output "app_registration_client_secret_id" {
  value = module.hurdle_labs.app_registration_client_secret_id
}

output "app_registration_client_secret_value" {
  value     = module.hurdle_labs.app_registration_client_secret_value
  sensitive = true
}

output "service_principal_object_id" {
  value = module.hurdle_labs.service_principal_object_id
}

output "resource_group_name" {
  value = module.hurdle_labs.resource_group_name
}

output "resource_group_id" {
  value = module.hurdle_labs.resource_group_id
}

output "bridge_public_fqdn" {
  value = module.hurdle_labs.bridge_public_fqdn
}

output "bridge_public_ip_address" {
  value = module.hurdle_labs.bridge_public_ip_address
}
