# Infrastructure Consumer Example

This is the recommended first state for split-permission deployments. It deploys only the Hurdle Labs Azure infrastructure and outputs the resource group ID required by the identity operator.

## Prerequisites
- Make sure you have the prerequisite CLI tools and Azure permissions outlined in the [root documentation page](../../)

## How to Create Standard Azure Resources from Scratch
1. Plan a Bridge Web Domain and Retrieve a Hurdle Bridge Secret
    - Establish what `<bridge_subdomain>.AZURE_REGION.cloudapp.azure.com` domain you want to use.
    - Go to https://manage.hurdle.live/lab/bridges/new and enter the Bridge domain you want to use, with a WebSocket protocol prefix. For example:`wss://COMPANY-NAME-hurdle-bridge.AZURE_REGION.cloudapp.azure.com`.
    - Hurdle will automatically email you a Bridge Secret. You must paste this alphanumeric string into Terraform variable `bridge_lab_secret`.
2. Extract files from this `examples/infra-standard` documentation folder to a directory on your local machine.
3. Copy example variables to recognised Terraform name:
    ```shell
    cp terraform.example.tfvars terraform.tfvars
    ```
4. Populate `terraform.tfvars` with your real values. At minimum, these ones must be populated:
   - `subscription_id`
   - `tenant_id`
   - `location`
   - `resource_group_name`
   - `app_display_name`
   - `bridge_subdomain`
   - `bridge_admin_username`
   - `bridge_vm_size` (recommended minimum: `Standard_D4s_v3`)
   - `bridge_technical_contact_email`
   - `bridge_lab_secret`
   - `bridge_source_image_id`
   - `bridge_ssh_public_key`
   - `bridge_ssh_allowed_cidrs`
5. Initialise Terraform:
    ```shell
    terraform init
    ```
6. Validate your current variable values
    ```shell
    terraform validate
    ```
7. Generate a Terraform plan:
    ```shell
    terraform plan -out="infra.tfplan"
    ```
8. If you are happy with the plan, apply it:
    ```shell
    terraform apply "infra.tfplan"
    ```
9. Load the Bridge's URL (`bridge_public_fqdn` from `terraform.tfstate`) in your web browser. You should see a GuacWS server welcome page like this:
   ![Screenshot of GuacWS holding page loaded in a web browser](https://raw.githubusercontent.com/hurdlegroup/terraform-azurerm-hurdle-labs/6aecb2a11709ccac7a0e164b4a771fc490a241aa/docs/images/screenshot-guacws-holding-page.png)

## How to Import Existing Azure Resources into Terraform and Then Upgrade Hurdle Bridge
**Note:** these instructions use PowerShell not Bash, because that's been the most common use-case so far.

1. Extract files from this `examples/infra-standard` documentation folder to a directory on your local machine.
2. Set `terraform.tfvars` values to match existing Azure resources as closely as possible.
3. Enable verbose Terraform logging and initialise Terraform:
    ```powershell
    $env:TF_LOG = "INFO"
    terraform init
    ```
4. Import existing Azure resources into Terraform:
    ```powershell
    terraform import module.hurdle_labs_infra.azurerm_resource_group.hurdle_lab "{RESOURCE_GROUP_ID}"
    
    terraform import module.hurdle_labs_infra.azurerm_virtual_network.hurdle_lab "{VIRTUAL_NETWORK_ID}"
    terraform import module.hurdle_labs_infra.azurerm_subnet.bridge "{BRIDGE_SUBNET_ID}"
    terraform import module.hurdle_labs_infra.azurerm_subnet.machines "{MACHINES_SUBNET_ID}"
    
    terraform import module.hurdle_labs_infra.azurerm_public_ip.machines_nat[0] "{MACHINES_NAT_PUBLIC_IP_ID}"
    terraform import module.hurdle_labs_infra.azurerm_nat_gateway.machines[0] "{MACHINES_NAT_GATEWAY_ID}"
    terraform import module.hurdle_labs_infra.azurerm_nat_gateway_public_ip_association.machines[0] "{MACHINES_NAT_GATEWAY_ID}|{MACHINES_NAT_PUBLIC_IP_ID}"
    terraform import module.hurdle_labs_infra.azurerm_subnet_nat_gateway_association.machines[0] "{MACHINES_SUBNET_ID}"
    
    terraform import module.hurdle_labs_infra.azurerm_linux_virtual_machine.bridge "{BRIDGE_VM_ID}"
    terraform import module.hurdle_labs_infra.azurerm_public_ip.bridge "{BRIDGE_PUBLIC_IP_ID}"
    terraform import module.hurdle_labs_infra.azurerm_network_security_group.bridge "{BRIDGE_NSG_ID}"
    terraform import module.hurdle_labs_infra.azurerm_network_interface.bridge "{BRIDGE_NIC_ID}"
    terraform import module.hurdle_labs_infra.azurerm_network_interface_security_group_association.bridge "{BRIDGE_NIC_ID}|{BRIDGE_NSG_ID}"
    
    terraform import module.hurdle_labs_infra.azurerm_network_security_rule.bridge_http "{BRIDGE_HTTP_NSG_RULE_ID}"
    terraform import module.hurdle_labs_infra.azurerm_network_security_rule.bridge_https[0] "{BRIDGE_HTTPS_NSG_RULE_ID}"
    terraform import module.hurdle_labs_infra.azurerm_network_security_rule.bridge_ssh "{BRIDGE_SSH_NSG_RULE_ID}"
    ```
5. Generate a Terraform plan to confirm any existing differences with Azure. (It's fine if there are differences; this is just an informational step.)
    ```powershell
    terraform plan -out "infra.tfplan"
    # Output will be either
    # (1) Unchanged
    No changes. Your infrastructure matches the configuration.
    # Or (2) slight existing differences:
    Terraform will perform the following actions:
    ...
    ```
6. In `terraform.tfvars`, change `bridge_source_image_id` from `1.1.0` to `1.4.0`
7. Generate Terraform plan to upgrade the bridge:
    ```powershell
    terraform plan -out "infra.tfplan"
    ```
8. Apply Terraform plan to upgrade the bridge:
    ```powershell
    terraform apply "infra.tfplan"
    ```

## How to Decommission Azure Assets
Use this section when your real intention is to remove Azure resources, not repair Terraform state.

The key rule is:
- if you want the Azure resource gone, destroy it through Terraform
- do not delete it in the Azure Portal first and then try to make Terraform catch up afterwards

Simply run:
```shell
terraform plan -destroy -out "infra-destroy.tfplan"
terraform apply "infra-destroy.tfplan"
```
