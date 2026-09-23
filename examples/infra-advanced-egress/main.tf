module "hurdle_labs_infra" {
  source  = "hurdlegroup/hurdle-labs/azurerm//modules/azure-hurdle-lab-infra"
  version = "1.3.0"

  location                                     = var.location
  resource_group_name                          = var.resource_group_name
  bridge_subdomain                             = var.bridge_subdomain
  bridge_admin_username                        = var.bridge_admin_username
  bridge_vm_size                               = var.bridge_vm_size
  bridge_technical_contact_email               = var.bridge_technical_contact_email
  bridge_lab_secret                            = var.bridge_lab_secret
  bridge_source_image_id                       = var.bridge_source_image_id
  bridge_ssh_public_key                        = var.bridge_ssh_public_key
  bridge_ssh_allowed_cidrs                     = var.bridge_ssh_allowed_cidrs
  machines_egress_mode                         = "firewall_customer_existing"
  machines_byo_firewall_private_ip             = var.machines_byo_firewall_private_ip
  machines_byo_route_table_name                = var.machines_byo_route_table_name
  machines_byo_route_table_resource_group_name = var.machines_byo_route_table_resource_group_name
}
