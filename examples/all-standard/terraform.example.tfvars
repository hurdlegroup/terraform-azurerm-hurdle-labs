# Retrieve from Azure CLI:
#   az account show --query id -o tsv
subscription_id = "00000000-0000-0000-0000-000000000000"

# Retrieve from Azure CLI:
#   az account show --query tenantId -o tsv
tenant_id = "00000000-0000-0000-0000-000000000000"

# List regions in which your Azure tenant already has resources, and then pick your preferred one:
#   az resource list --query "[].location" -o tsv | sort -u
location = "uksouth"

# Set manually: must be globally unique within your subscription naming conventions.
# Check if the name already exists in your subscription:
#   az group exists --name "rg-hurdle-labs"
resource_group_name = "rg-hurdle-labs"

# Set manually: app registration display name (globally visible in tenant and should follow your naming policy).
app_display_name = "Hurdle Labs App Registration"

# Optional: defaults to "<app_display_name> Secret v1" when null.
app_secret_display_name = null

# Set manually: app secret lifetime in hours (6 months = 4380h).
app_secret_lifetime = "4380h"

# Set manually: bridge public DNS label used as-is.
# Used as: <bridge_subdomain>.AZURE_REGION.cloudapp.azure.com
bridge_subdomain = "terraform-v2-hurdle-bridge"

# Set manually: Linux username for SSH login on the bridge VM.
bridge_admin_username = "azureuser"

# Set manually: bridge VM size (recommended minimum: Standard_D4s_v3).
bridge_vm_size = "Standard_D4s_v3"

# Optional: bridge ingress profile.
# - "direct_pip" (default): direct bridge ingress via pip-hurdle-lab-bridge.
# - "appgw_waf": ingress via Application Gateway/WAF.
bridge_ingress_mode = "direct_pip"

# Required only when bridge_ingress_mode = "appgw_waf":
# - bridge_appgw_tls_key_vault_secret_id must be a Key Vault certificate secret ID.
# - bridge_appgw_key_vault_uami_id must be a User Assigned Managed Identity resource ID that has read access to that Key Vault secret.
# - Retrieve via `az identity show --resource-group "<UAMI_RG>" --name "<UAMI_NAME>" --query id -o tsv`
bridge_appgw_tls_key_vault_secret_id = null
bridge_appgw_key_vault_uami_id       = null

# Optional: outbound egress profile for lab VMs in machines subnet.
# - "nat" (default): subnet egress via NAT Gateway managed by this module.
# - "firewall_module_provisioned": subnet egress via Azure Firewall created by this module.
# - "firewall_customer_existing": subnet egress via an existing customer-managed firewall private IP.
machines_egress_mode = "nat"

# Optional: managed firewall settings used only when machines_egress_mode = "firewall_module_provisioned".
machines_managed_firewall_name        = "fw-hurdle-lab-machines-egress"
machines_managed_firewall_subnet_cidr = "10.200.254.0/26"

# Required only when machines_egress_mode = "firewall_customer_existing": private IP of existing customer firewall.
machines_byo_firewall_private_ip = null

# Optional when machines_egress_mode = "firewall_customer_existing":
# if provided, module uses this existing route table and associates machines subnet to it.
machines_byo_route_table_name                = null
machines_byo_route_table_resource_group_name = null

# Set manually: technical contact email used for Let's Encrypt registration.
bridge_technical_contact_email = "platform@example.com"

# Set manually: Alphanumeric secret that should've been automatically emailed to you after
# you registered the Azure Lab Bridge's public domain (`*.AZURE_REGION.cloudapp.azure.com`) with Hurdle via https://manage.hurdle.live/lab/bridges/new
bridge_lab_secret = "LONG_ALPHANUMERIC_STRING_FROM_HURDLE_EMAIL"

# Full Azure image ID for bridge VM source image.
# If you want a specific version, retrieve Community Gallery Image ID from Azure CLI:
#   az sig image-version show-community --public-gallery-name hurdle-ec6051c3-68bb-4651-a552-8255caddd442 --gallery-image-definition hurdleBridge --gallery-image-version 1.4.0 --location uksouth --query uniqueId -o tsv
bridge_source_image_id = "/communityGalleries/hurdle-ec6051c3-68bb-4651-a552-8255caddd442/images/hurdleBridge/versions/latest"

# Generate keypair if needed:
#   ssh-keygen -t ed25519 -C "azure-hurdle-lab-bridge" -f ./azure_hurdle_lab_bridge_ed25519
# Then copy public key value returned by:
#   cat ./azure_hurdle_lab_bridge_ed25519.pub
bridge_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..."

# Retrieve your current public IP CIDR (run while connected to workplace VPN if required):
#   printf '%s/32\n' "$(curl -s https://api.ipify.org)"
bridge_ssh_allowed_cidrs = [
  "0.0.0.0/32",
]
