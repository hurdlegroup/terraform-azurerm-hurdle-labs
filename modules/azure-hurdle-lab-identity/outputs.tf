output "app_registration_client_id" {
  description = "Client ID of app registration."
  value       = azuread_application.hurdle_lab.client_id
}

output "service_principal_object_id" {
  description = "Object ID of the service principal."
  value       = azuread_service_principal.hurdle_lab.object_id
}

output "app_registration_client_secret_value" {
  description = "Client secret value for the app registration."
  value       = azuread_application_password.hurdle_lab.value
  sensitive   = true
}

output "app_registration_client_secret_name" {
  description = "Display name of the app registration client secret."
  value       = azuread_application_password.hurdle_lab.display_name
}

output "app_registration_client_secret_id" {
  description = "ID of the app registration client secret."
  value       = azuread_application_password.hurdle_lab.id
}
