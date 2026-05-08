variable "location" {
  description = "Azure region for resource deployment."
  type        = string
}

variable "bridge_subdomain_slug" {
  description = "Subdomain slug used to build the bridge public DNS label."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.bridge_subdomain_slug))
    error_message = "bridge_subdomain_slug must contain only letters, numbers, and hyphens for Azure DNS label compatibility."
  }
}

variable "bridge_admin_username" {
  description = "Admin username for bridge VM SSH login."
  type        = string
}

variable "bridge_ssh_public_key" {
  description = "SSH public key for the bridge VM admin user."
  type        = string
}

variable "bridge_ssh_allowed_cidrs" {
  description = "List of CIDRs allowed to SSH to bridge VM."
  type        = list(string)
}

variable "bridge_technical_contact_email" {
  description = "Technical contact email used for Let's Encrypt registration in guacws config."
  type        = string
}

variable "bridge_lab_secret" {
  description = "Secret value written into guacws Cipher.Key."
  type        = string
  sensitive   = true
}

variable "bridge_source_image_id" {
  description = "Full Azure image resource ID for the bridge VM source image."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name."
  type        = string
  default     = "vnet-hurdle-lab"
}

variable "bridge_subnet_name" {
  description = "Bridge subnet name."
  type        = string
  default     = "snet-hurdle-lab-bridge"
}

variable "machines_subnet_name" {
  description = "Lab machines subnet name."
  type        = string
  default     = "snet-hurdle-lab-machines"
}

variable "bridge_vm_name" {
  description = "Bridge VM name."
  type        = string
  default     = "vm-hurdle-lab-bridge"
}

variable "bridge_nsg_name" {
  description = "Bridge NSG name."
  type        = string
  default     = "nsg-hurdle-lab-bridge"
}

variable "bridge_pip_name" {
  description = "Bridge public IP name."
  type        = string
  default     = "pip-hurdle-lab-bridge"
}

variable "machines_nat_name" {
  description = "Machines NAT gateway name."
  type        = string
  default     = "nat-hurdle-lab-machines"
}

variable "vnet_cidr" {
  description = "CIDR for the VNet."
  type        = string
  default     = "10.200.0.0/16"
}

variable "bridge_subnet_cidr" {
  description = "CIDR for bridge subnet."
  type        = string
  default     = "10.200.1.0/24"
}

variable "machines_subnet_cidr" {
  description = "CIDR for lab machines subnet."
  type        = string
  default     = "10.200.2.0/24"
}

variable "bridge_cloud_init" {
  description = "Inline cloud-init YAML content for bridge VM."
  type        = string
  default     = null
}

variable "bridge_cloud_init_template" {
  description = "Path to cloud-init template file rendered with no vars."
  type        = string
  default     = null
}

variable "bridge_vm_size" {
  description = "Size of the bridge VM."
  type        = string
}

variable "bridge_os_disk_storage_account_type" {
  description = "Storage account type for bridge VM OS disk."
  type        = string
  default     = "Standard_LRS"
}

variable "bridge_os_disk_size_gb" {
  description = "Optional explicit size (GB) for bridge VM OS disk. Null uses image default."
  type        = number
  default     = null
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
