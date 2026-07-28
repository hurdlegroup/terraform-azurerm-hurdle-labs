# Retrieve from Azure CLI:
#   az account show --query id -o tsv
subscription_id = "00000000-0000-0000-0000-000000000000"

# Retrieve from Azure CLI:
#   az account show --query tenantId -o tsv
tenant_id = "00000000-0000-0000-0000-000000000000"

# ID of the Azure resource group that contains Hurdle Labs infrastructure
resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hurdle-labs"

# Set manually: app registration display name (globally visible in tenant and should follow your naming policy).
app_display_name = "Hurdle Labs App Registration"

# Optional: defaults to "<app_display_name> Secret v1" when null.
app_secret_display_name = null

# Set manually: app secret lifetime in hours (6 months = 4380h).
app_secret_lifetime = "4380h"
