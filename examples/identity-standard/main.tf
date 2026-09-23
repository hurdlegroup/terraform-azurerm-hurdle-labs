module "hurdle_labs_identity" {
  source  = "hurdlegroup/hurdle-labs/azurerm//modules/azure-hurdle-lab-identity"
  version = "1.3.0"

  subscription_id         = var.subscription_id
  resource_group_id       = var.resource_group_id
  app_display_name        = var.app_display_name
  app_secret_display_name = var.app_secret_display_name
  app_secret_lifetime     = var.app_secret_lifetime
}
