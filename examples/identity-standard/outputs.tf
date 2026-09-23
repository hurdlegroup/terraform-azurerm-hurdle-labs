// These outputs intentionally re-export the child module API; child-module resources and locals are scope-isolated.
output "app_registration_client_id" {
  description = "Client ID (application ID) of the created app registration."
  value       = module.hurdle_labs_identity.app_registration_client_id
}

output "service_principal_object_id" {
  description = "Object ID of the created service principal."
  value       = module.hurdle_labs_identity.service_principal_object_id
}

output "app_registration_client_secret_value" {
  description = "Client secret value for the app registration."
  value       = module.hurdle_labs_identity.app_registration_client_secret_value
  sensitive   = true
}

output "app_registration_client_secret_name" {
  description = "Display name of the created app registration client secret."
  value       = module.hurdle_labs_identity.app_registration_client_secret_name
}

output "app_registration_client_secret_id" {
  description = "Resource ID of the created app registration client secret."
  value       = module.hurdle_labs_identity.app_registration_client_secret_id
}
