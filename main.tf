module "azure_hurdle_lab_infra" {
  source = "./modules/azure-hurdle-lab-infra"

  location                       = var.location
  bridge_subdomain_slug          = var.bridge_subdomain_slug
  bridge_admin_username          = var.bridge_admin_username
  bridge_ssh_public_key          = var.bridge_ssh_public_key
  bridge_ssh_allowed_cidrs       = var.bridge_ssh_allowed_cidrs
  bridge_technical_contact_email = var.bridge_technical_contact_email
  bridge_lab_secret              = var.bridge_lab_secret
  bridge_source_image_id         = var.bridge_source_image_id

  resource_group_name                          = var.resource_group_name
  vnet_name                                    = var.vnet_name
  bridge_subnet_name                           = var.bridge_subnet_name
  machines_subnet_name                         = var.machines_subnet_name
  bridge_vm_name                               = var.bridge_vm_name
  bridge_nsg_name                              = var.bridge_nsg_name
  bridge_pip_name                              = var.bridge_pip_name
  machines_nat_name                            = var.machines_nat_name
  machines_egress_mode                         = var.machines_egress_mode
  machines_route_table_name                    = var.machines_route_table_name
  machines_managed_firewall_name               = var.machines_managed_firewall_name
  machines_managed_firewall_pip_name           = var.machines_managed_firewall_pip_name
  machines_managed_firewall_subnet_cidr        = var.machines_managed_firewall_subnet_cidr
  machines_byo_firewall_private_ip             = var.machines_byo_firewall_private_ip
  machines_byo_route_table_name                = var.machines_byo_route_table_name
  machines_byo_route_table_resource_group_name = var.machines_byo_route_table_resource_group_name

  vnet_cidr            = var.vnet_cidr
  bridge_subnet_cidr   = var.bridge_subnet_cidr
  machines_subnet_cidr = var.machines_subnet_cidr

  bridge_cloud_init                   = var.bridge_cloud_init
  bridge_cloud_init_template          = var.bridge_cloud_init_template
  bridge_vm_size                      = var.bridge_vm_size
  bridge_os_disk_storage_account_type = var.bridge_os_disk_storage_account_type
  bridge_os_disk_size_gb              = var.bridge_os_disk_size_gb
  tags                                = var.tags
}

module "azure_hurdle_lab_identity" {
  source = "./modules/azure-hurdle-lab-identity"

  subscription_id         = var.subscription_id
  app_display_name        = var.app_display_name
  app_secret_display_name = var.app_secret_display_name
  app_secret_lifetime     = var.app_secret_lifetime
  resource_group_id       = module.azure_hurdle_lab_infra.resource_group_id
  depends_on              = [module.azure_hurdle_lab_infra]
}
