resource "azuread_application" "hurdle_lab" {
  display_name = var.app_display_name
}

resource "azuread_service_principal" "hurdle_lab" {
  client_id = azuread_application.hurdle_lab.client_id
}

data "azurerm_subscription" "current" {
  subscription_id = var.subscription_id
}

data "azurerm_role_definition" "contributor" {
  name  = "Contributor"
  scope = data.azurerm_subscription.current.id
}

data "azurerm_role_definition" "quota_request_operator" {
  name  = "Quota Request Operator"
  scope = data.azurerm_subscription.current.id
}

resource "azurerm_role_assignment" "sp_contributor_rg" {
  scope              = var.resource_group_id
  role_definition_id = data.azurerm_role_definition.contributor.id
  principal_id       = azuread_service_principal.hurdle_lab.object_id
}

resource "azurerm_role_assignment" "sp_quota_operator_subscription" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = data.azurerm_role_definition.quota_request_operator.id
  principal_id       = azuread_service_principal.hurdle_lab.object_id
}
