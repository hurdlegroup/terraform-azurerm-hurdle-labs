variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "bridge_subdomain" {
  type = string
}

variable "bridge_admin_username" {
  type = string
}

variable "bridge_vm_size" {
  type = string
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

variable "bridge_ssh_public_key" {
  type = string
}

variable "bridge_ssh_allowed_cidrs" {
  type = list(string)
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
