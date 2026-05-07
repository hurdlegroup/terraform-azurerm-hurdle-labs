output "app_registration_client_id" {
  description = "Client ID of app registration."
  value       = azuread_application.hurdle_lab.client_id
}

output "service_principal_object_id" {
  description = "Object ID of the service principal."
  value       = azuread_service_principal.hurdle_lab.object_id
}
