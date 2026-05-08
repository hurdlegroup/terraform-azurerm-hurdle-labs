variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "location" {
  type = string
}

variable "bridge_subdomain_slug" {
  type = string
}

variable "bridge_admin_username" {
  type = string
}

variable "bridge_ssh_public_key" {
  type = string
}

variable "bridge_ssh_allowed_cidrs" {
  type = list(string)
}

variable "bridge_technical_contact_email" {
  type = string
}

variable "bridge_lab_secret" {
  type      = string
  sensitive = true
}

variable "bridge_source_image_id" {
  type = string
}

variable "app_display_name" {
  type = string
}

variable "app_secret_display_name" {
  type    = string
  default = null
}

variable "app_secret_lifetime" {
  type    = string
  default = "4380h"
}

variable "resource_group_name" {
  type = string
}

variable "vnet_name" {
  type    = string
  default = "vnet-hurdle-lab"
}

variable "bridge_subnet_name" {
  type    = string
  default = "snet-hurdle-lab-bridge"
}

variable "machines_subnet_name" {
  type    = string
  default = "snet-hurdle-lab-machines"
}

variable "bridge_vm_name" {
  type    = string
  default = "vm-hurdle-lab-bridge"
}

variable "bridge_nsg_name" {
  type    = string
  default = "nsg-hurdle-lab-bridge"
}

variable "bridge_pip_name" {
  type    = string
  default = "pip-hurdle-lab-bridge"
}

variable "machines_nat_name" {
  type    = string
  default = "nat-hurdle-lab-machines"
}

variable "vnet_cidr" {
  type    = string
  default = "10.200.0.0/16"
}

variable "bridge_subnet_cidr" {
  type    = string
  default = "10.200.1.0/24"
}

variable "machines_subnet_cidr" {
  type    = string
  default = "10.200.2.0/24"
}

variable "bridge_cloud_init" {
  type    = string
  default = null
}

variable "bridge_cloud_init_template" {
  type    = string
  default = null
}

variable "bridge_vm_size" {
  type = string
}

variable "bridge_os_disk_storage_account_type" {
  type    = string
  default = "Standard_LRS"
}

variable "bridge_os_disk_size_gb" {
  type    = number
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
