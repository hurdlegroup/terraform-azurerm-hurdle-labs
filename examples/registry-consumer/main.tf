module "hurdle_labs" {
  source  = "hurdlegroup/hurdle-labs/azurerm"
  version = "1.0.0"

  subscription_id                = var.subscription_id
  tenant_id                      = var.tenant_id
  location                       = var.location
  resource_group_name            = var.resource_group_name
  bridge_subdomain_slug          = var.bridge_subdomain_slug
  bridge_admin_username          = var.bridge_admin_username
  bridge_vm_size                 = var.bridge_vm_size
  bridge_technical_contact_email = var.bridge_technical_contact_email
  bridge_lab_secret              = var.bridge_lab_secret
  bridge_source_image_id         = var.bridge_source_image_id
  bridge_ssh_public_key          = var.bridge_ssh_public_key
  bridge_ssh_allowed_cidrs       = var.bridge_ssh_allowed_cidrs

  app_display_name        = var.app_display_name
  app_secret_display_name = var.app_secret_display_name
  app_secret_lifetime     = var.app_secret_lifetime
}
