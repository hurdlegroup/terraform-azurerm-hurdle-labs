subscription_id     = "00000000-0000-0000-0000-000000000000"
tenant_id           = "00000000-0000-0000-0000-000000000000"
location            = "uksouth"
resource_group_name = "rg-hurdle-labs"

# Set manually: bridge public DNS label used as-is.
# Used as: <bridge_subdomain>.AZURE_REGION.cloudapp.azure.com
bridge_subdomain = "terraform-v2-hurdle-bridge"

# Set manually: Linux username for SSH login on the bridge VM.
bridge_admin_username = "azureuser"

# Set manually: bridge VM size (recommended minimum: Standard_D4s_v3).
bridge_vm_size = "Standard_D4s_v3"

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
