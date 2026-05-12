variable "subscription_id" {
  description = "Azure subscription ID used for subscription-scoped operations."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID used by azurerm and azuread providers."
  type        = string
}

variable "location" {
  description = "Azure region where infrastructure resources are deployed."
  type        = string
}

variable "bridge_subdomain_slug" {
  description = "Slug used to generate bridge public DNS label: <slug>-hurdle-bridge.<region>.cloudapp.azure.com."
  type        = string
}

variable "bridge_admin_username" {
  description = "Linux admin username for SSH access to the bridge VM."
  type        = string
}

variable "bridge_ssh_public_key" {
  description = "SSH public key injected into the bridge VM for key-based login."
  type        = string
}

variable "bridge_ssh_allowed_cidrs" {
  description = "CIDR list allowed to SSH (port 22) into the bridge VM."
  type        = list(string)
}

variable "bridge_technical_contact_email" {
  description = "Technical contact email used by Let's Encrypt configuration on the bridge."
  type        = string
}

variable "bridge_lab_secret" {
  description = "Hurdle lab bridge shared secret written into guacws Cipher.Key."
  type        = string
  sensitive   = true
}

variable "bridge_source_image_id" {
  description = "Full Azure image resource ID used as source image for the bridge VM."
  type        = string
}

variable "app_display_name" {
  description = "Display name for the Azure Entra app registration."
  type        = string
}

variable "app_secret_display_name" {
  description = "Optional display name for the app registration client secret. Null defaults to '<app_display_name> Secret v1'."
  type        = string
  default     = null
}

variable "app_secret_lifetime" {
  description = "App registration secret lifetime duration in hours, e.g. 4380h for 6 months."
  type        = string
  default     = "4380h"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group created for Hurdle lab infrastructure."
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name for Hurdle lab infrastructure."
  type        = string
  default     = "vnet-hurdle-lab"
}

variable "bridge_subnet_name" {
  description = "Subnet name used for the persistent bridge VM."
  type        = string
  default     = "snet-hurdle-lab-bridge"
}

variable "machines_subnet_name" {
  description = "Subnet name used for ephemeral learner/lab VMs."
  type        = string
  default     = "snet-hurdle-lab-machines"
}

variable "bridge_vm_name" {
  description = "Name of the persistent bridge virtual machine."
  type        = string
  default     = "vm-hurdle-lab-bridge"
}

variable "bridge_nsg_name" {
  description = "Network Security Group name for bridge VM traffic policy."
  type        = string
  default     = "nsg-hurdle-lab-bridge"
}

variable "bridge_pip_name" {
  description = "Public IP resource name assigned to the bridge VM."
  type        = string
  default     = "pip-hurdle-lab-bridge"
}

variable "machines_nat_name" {
  description = "NAT Gateway name used for machines subnet outbound egress."
  type        = string
  default     = "nat-hurdle-lab-machines"
}

variable "machines_egress_mode" {
  description = "Outbound egress mode for lab machines subnet. Valid values: nat, firewall_module_provisioned, firewall_customer_existing."
  type        = string
  default     = "nat"
}

variable "machines_route_table_name" {
  description = "Route table name for machines subnet when firewall egress is enabled."
  type        = string
  default     = "rt-hurdle-lab-machines-egress"
}

variable "machines_managed_firewall_name" {
  description = "Azure Firewall name when using firewall_module_provisioned mode."
  type        = string
  default     = "fw-hurdle-lab-machines-egress"
}

variable "machines_managed_firewall_pip_name" {
  description = "Azure Firewall public IP resource name when using firewall_module_provisioned mode."
  type        = string
  default     = "pip-fw-hurdle-lab-machines-egress"
}

variable "machines_managed_firewall_subnet_cidr" {
  description = "CIDR for AzureFirewallSubnet when using firewall_module_provisioned mode."
  type        = string
  default     = "10.200.254.0/26"
}

variable "machines_byo_firewall_private_ip" {
  description = "Existing firewall private IP used when machines_egress_mode is firewall_customer_existing."
  type        = string
  default     = null
}

variable "machines_byo_route_table_name" {
  description = "Existing route table name for machines subnet when using firewall_customer_existing. If null, module creates route table."
  type        = string
  default     = null
}

variable "machines_byo_route_table_resource_group_name" {
  description = "Resource group containing machines_byo_route_table_name when using firewall_customer_existing."
  type        = string
  default     = null
}

variable "vnet_cidr" {
  description = "Address space CIDR for the virtual network."
  type        = string
  default     = "10.200.0.0/16"
}

variable "bridge_subnet_cidr" {
  description = "CIDR for the bridge subnet."
  type        = string
  default     = "10.200.1.0/24"
}

variable "machines_subnet_cidr" {
  description = "CIDR for the machines subnet."
  type        = string
  default     = "10.200.2.0/24"
}

variable "bridge_cloud_init" {
  description = "Optional inline cloud-init content for the bridge VM. If null, generated default is used."
  type        = string
  default     = null
}

variable "bridge_cloud_init_template" {
  description = "Optional path to cloud-init template file for bridge VM customization."
  type        = string
  default     = null
}

variable "bridge_vm_size" {
  description = "Azure VM size for the bridge VM, e.g. Standard_D4s_v3."
  type        = string
}

variable "bridge_os_disk_storage_account_type" {
  description = "Storage account type for bridge VM OS disk."
  type        = string
  default     = "Standard_LRS"
}

variable "bridge_os_disk_size_gb" {
  description = "Optional explicit OS disk size in GB for bridge VM. Null uses image default."
  type        = number
  default     = null
}

variable "tags" {
  description = "Map of tags applied to supported resources."
  type        = map(string)
  default     = {}
}
