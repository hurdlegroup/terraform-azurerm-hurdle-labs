variable "location" {
  description = "Azure region where infrastructure resources are deployed."
  type        = string
}

variable "bridge_subdomain" {
  description = "Bridge public DNS label used as-is for <bridge_subdomain>.<region>.cloudapp.azure.com."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.bridge_subdomain))
    error_message = "bridge_subdomain must contain only letters, numbers, and hyphens for Azure DNS label compatibility."
  }
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

variable "bridge_allowed_origins" {
  description = "Origin list written into guacws WebSocket.AllowedOrigins. Empty list allows all origins."
  type        = list(string)
  default     = []
}

variable "bridge_source_image_id" {
  description = "Full Azure image resource ID used as source image for the bridge VM."
  type        = string
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

variable "bridge_ingress_mode" {
  description = "Ingress mode for bridge traffic. Valid values: direct_pip, appgw_waf."
  type        = string
  default     = "direct_pip"

  validation {
    condition     = contains(["direct_pip", "appgw_waf"], var.bridge_ingress_mode)
    error_message = "bridge_ingress_mode must be one of: direct_pip, appgw_waf."
  }
}

variable "bridge_edge_subnet_name" {
  description = "Subnet name used for Application Gateway when bridge_ingress_mode is appgw_waf."
  type        = string
  default     = "snet-hurdle-lab-edge"
}

variable "bridge_edge_subnet_cidr" {
  description = "CIDR for Application Gateway subnet when bridge_ingress_mode is appgw_waf."
  type        = string
  default     = "10.200.3.0/24"
}

variable "bridge_appgw_name" {
  description = "Application Gateway name when bridge_ingress_mode is appgw_waf."
  type        = string
  default     = "appgw-hurdle-lab-bridge"
}

variable "bridge_appgw_pip_name" {
  description = "Application Gateway public IP name when bridge_ingress_mode is appgw_waf."
  type        = string
  default     = "pip-appgw-hurdle-lab-bridge"
}

variable "bridge_appgw_sku_name" {
  description = "Application Gateway SKU name when bridge_ingress_mode is appgw_waf."
  type        = string
  default     = "WAF_v2"
}

variable "bridge_appgw_sku_tier" {
  description = "Application Gateway SKU tier when bridge_ingress_mode is appgw_waf."
  type        = string
  default     = "WAF_v2"
}

variable "bridge_appgw_capacity" {
  description = "Application Gateway fixed capacity when bridge_ingress_mode is appgw_waf."
  type        = number
  default     = 2
}

variable "bridge_appgw_waf_policy_name" {
  description = "WAF policy name attached to bridge Application Gateway when bridge_ingress_mode is appgw_waf."
  type        = string
  default     = "wafp-hurdle-lab-bridge"
}

variable "bridge_appgw_tls_key_vault_secret_id" {
  description = "Key Vault certificate secret ID used by Application Gateway HTTPS listener in appgw_waf mode."
  type        = string
  default     = null

  validation {
    condition     = var.bridge_ingress_mode != "appgw_waf" || var.bridge_appgw_tls_key_vault_secret_id != null
    error_message = "bridge_appgw_tls_key_vault_secret_id must be set when bridge_ingress_mode is appgw_waf."
  }
}

variable "bridge_appgw_key_vault_uami_id" {
  description = "User-assigned managed identity ID attached to Application Gateway for Key Vault certificate access in appgw_waf mode."
  type        = string
  default     = null

  validation {
    condition     = var.bridge_ingress_mode != "appgw_waf" || var.bridge_appgw_key_vault_uami_id != null
    error_message = "bridge_appgw_key_vault_uami_id must be set when bridge_ingress_mode is appgw_waf."
  }
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

  validation {
    condition     = contains(["nat", "firewall_module_provisioned", "firewall_customer_existing"], var.machines_egress_mode)
    error_message = "machines_egress_mode must be one of: nat, firewall_module_provisioned, firewall_customer_existing."
  }
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

  validation {
    condition     = var.machines_egress_mode != "firewall_customer_existing" || var.machines_byo_firewall_private_ip != null
    error_message = "machines_byo_firewall_private_ip must be set when machines_egress_mode is firewall_customer_existing."
  }
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
