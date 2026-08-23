# Deploy Hurdle Labs in Azure with Terraform

## Architecture and Objectives

### Objective
Deploy the Azure resources required for your organisation to use Hurdle Labs, with a strict separation between identity-plane provisioning and infrastructure-plane provisioning.

### Target Architecture

Default Azure architecture created by this module:

```text
Microsoft Azure Tenant (https://portal.azure.com)
├── App Registration (Service Principal): app-hurdle-lab
│   ├── Granted "Contributor" role to Resource Group: rg-hurdle-lab
│   └── Granted "Quota Request Operator" role for the subscription the resource group belongs to
│
└── Azure Subscription
    └── Resource Group: rg-hurdle-lab
        ├── Virtual Network: vnet-hurdle-lab
        │   ├── Subnet: snet-hurdle-lab-bridge
        │   │   └── Bridge VM (permanent): vm-hurdle-lab-bridge
        │   │       ├── Attached pip-hurdle-lab-bridge
        │   │       ├── Attached nsg-hurdle-lab-bridge
        │   │       ├── Community Image: `hurdleBridge/latest`
        │   │       │   └── Includes lab tunnel services: GuacD and GuacWS
        │   │       └── Requires SSH-based configuration before first use
        │   │
        │   └── Subnet: snet-hurdle-lab-machines
        │       ├── Attached nat-hurdle-lab-machines
        │       └── Lab VMs (ephemeral, created per session/attendee)
        │
        ├── NAT Gateway: nat-hurdle-lab-machines
        │   └── Used by snet-hurdle-lab-machines
        │
        ├── Public IP: pip-hurdle-lab-bridge
        │   ├── Used by vm-hurdle-lab-bridge
        │   └── Assign domain: COMPANY-NAME-hurdle-bridge.AZURE_REGION.cloudapp.azure.com
        │
        └── Network Security Group: nsg-hurdle-lab-bridge
            ├── Network Security Group for the Bridge VM `vm-hurdle-lab-bridge`
            ├── Is automatically created when you create `vm-hurdle-lab-bridge`.
            └── Remember to allow SSH connections from your workplace VPN's public IP address!

Your workplace VPN provider
├── If you use a VPN, then whitelist your VPN's IP in the Azure Bridge's inbound rules e.g. `nsg-hurdle-lab-bridge` above.
└── If you don't, then you won't be able to SSH into `vm-hurdle-lab-bridge`.

Hurdle Trainer Dashboard (https://manage.hurdle.live)
├── "Hurdle Lab Provider" (https://manage.hurdle.live/lab/providers/new)
│   └── Tell Hurdle which Azure App Registration to use e.g. `app-hurdle-lab` above
│
├── "Hurdle Lab Bridge" (https://manage.hurdle.live/lab/bridges/new)
│   └── Defines connection to Azure Bridge e.g. wss://COMPANY-NAME-hurdle-bridge.AZURE_REGION.cloudapp.azure.com
│
├── "Hurdle Lab" (https://manage.hurdle.live/lab/instances/new)
│   └── Defines VM size, image, VNet, lab subnet, etc
│
└── "Hurdle Lab Session" (https://manage.hurdle.live/training-sessions/new)
    └── Spins up ephemeral Lab VMs using the above Lab definition
    
Hurdle Conference App
├── This is what trainers and learners actually use to join sessions and interact with each other.
├── Web version: https://app.hurdle.live
├── Desktop versions for Windows/Mac/Ubuntu can be downloaded from: https://go.hurdle.live
└── The Web/Desktop app connects to your Azure Bridge VM (vm-hurdle-lab-bridge) via a WebSocket connection.
```

For more advanced ingress/egress architectures supported by this module, see:
- [`examples/infra-advanced-ingress`](./examples/infra-advanced-ingress): Lab Bridge ingress through Application Gateway WAF.
- [`examples/infra-advanced-egress`](./examples/infra-advanced-egress): Lab Machine egress through a firewall.


---

## Prerequisites

### Permission Prerequisites and Submodule Structure
| Submodule | Documentation                                                                                               | Manages                                                      | Required Azure CLI Permissions                                                                                     |
| --- |-------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| `azure-hurdle-lab-infra` | [GitHub](./modules/azure-hurdle-lab-infra), [Terraform Registry](./submodules/azure-hurdle-lab-infra)       | Resource group, networking, NAT, bridge NSG/public IP/NIC/VM | Create/update resource-group scoped network and compute resources                                                  |
| `azure-hurdle-lab-identity` | [GitHub](./modules/azure-hurdle-lab-identity), [Terraform Registry](./submodules/azure-hurdle-lab-identity) | App registration, service principal, and RBAC assignments    | Create Entra app registrations and service principals. Assign RBAC roles at resource-group and subscription scope. |

This separation allows IAM-privileged operators to handle identity resources, while infrastructure operators handle resource deployment without broad Entra permissions.

### Tooling Prerequisites
1. Install Azure CLI if you don't already have it ([Microsoft Documentation](https://developer.hashicorp.com/terraform/tutorials/azure-get-started/install-cli)): 
   - In Linux Shell
       ```shell
       curl -fsSL 'https://azurecliprod.blob.core.windows.net/$root/deb_install.sh' | sudo bash
       ```
   - In Windows Terminal
       ```powershell
       winget install --exact --id Microsoft.AzureCLI
       ```
2. Install Terraform CLI if you don't already have it ([Terraform Documentation](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)):
    - In Linux Shell
        ```shell
        sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
        gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update
        sudo apt-get install terraform
        # Optionally enable verbose logging when troubleshooting:
        echo 'export TF_LOG=INFO' >> ~/.bashrc
        source ~/.bashrc
        ```
    - In Windows Terminal
        ```powershell
        winget install --exact --id Hashicorp.Terraform
        # Optionally enable verbose logging when troubleshooting:
        $env:TF_LOG = "INFO"
        ```
3. Terraform depends CLI on Git. Install it you don't already have it ([Git Documentation](https://git-scm.com/install)):
    - In Linux Shell
        ```shell
        sudo apt update && sudo apt-get install git
        ```
    - In Windows Terminal
        ```powershell
        winget install --exact --id Git.Git
        ```
4. Login to Azure CLI and select the Azure subscription that will house your Hurdle Labs resources 
    ```bash
    # Forces Azure CLI to login via web browser instead of potentially tripping over local credentials:
    az login --use-device-code
    ```

### Hurdle Community Compute Gallery Prerequisites
Before provisioning the bridge VM, check that Hurdle's Community Compute Gallery is available in your target Azure region:
- Community gallery name: `hurdle-ec6051c3-68bb-4651-a552-8255caddd442`
- Community gallery title: `hurdlePublicImages`

Critical regional requirement:
- **`hurdlePublicImages` must be available in the exact same region as your planned bridge VM.**
- **Example #1:** If you set Terraform variable `location = "uksouth"`, then `hurdlePublicImages` must be available in Azure's `UK South` region before you can deploy.
- **Example #2:** You gain learners in a new region and want to reduce lab latency for them. Before your can deploy Hurdle Labs in this new region (e.g. `location = "northeurope"`), `hurdlePublicImages` must be available Azure's `North Europe` region.

If this step is skipped (or done in a different region), image will return no result and bridge VM provisioning will fail.

**If `hurdlePublicImages` is not currently available in your target region, then please open a support ticket with us**: https://help.customer.hurdle.live/servicedesk/customer/portal/2/create/44.
We'll then publish `hurdlePublicImages` in your region as soon as possible.

---

## Standard Deployment Approach
1. Deploy `module.azure-hurdle-lab-infra` using [`examples/infra-standard`](./examples/infra-standard)
2. Deploy `module.azure-hurdle-lab-identity` using [`examples/identity-standard`](./examples/identity-standard)
    - **Important:** You must apply `module.azure-hurdle-lab-infra` first because `module.azure-hurdle-lab-identity` needs the resource group to exist so it can assign the App Registration to it.

---

## 🚨 Important: Azure App Secret Rotation 🚨
- Hurdle orchestrates resources within your Azure resource group via an Azure App Registration.
- This Azure App Registration has a secret with a finite lifetime (of your choice) for security reasons.
- You are responsible for ensuring that your current Azure App Registration secret is populated in https://manage.hurdle.live/lab/providers.
- **If the App secret expires, <ins>then your Hurdle Lab Sessions will stop working.</ins>**
- **If you rotate the App secret in https://portal.azure.com but do not update the secret in https://manage.hurdle.live/lab/providers, <ins>then your Hurdle Lab Sessions will stop working.</ins>**
- Hurdle sends App secret expiry alerts 30/14/7/5/3/1 days before expiry and also shows expiry banners at the top of every page in https://manage.hurdle.live.
- Hurdle cannot rotate your Azure App secret on your behalf; only your Azure administrators can do that.
- **Strongly recommended:**
    - Create a policy document for rotating your Azure App secret on a regular schedule e.g. `SOP: Rotate Azure Hurdle App Secret Every 3/6/9/12 Months`.
    - Share this secret-rotation document widely within your IT team, so everyone knows how to do it, and you don't inadvertently have a Labs Training outage simply because a sysadmin was ill that day.
    - Auto-schedule a `Rotate Hurdle Azure App Secret` task in line with your chosen App secret lifetime. This task should instruct the Azure admin to:
        - Generate a new App secret in https://portal.azure.com and then paste it into https://manage.hurdle.live/lab/providers.
        - Start and join a Hurdle Lab Session from https://manage.hurdle.live/training-sessions to confirm that the new App secret works as expected.

---

## Other Deployment Approaches

### Import Existing Azure Assets into Terraform


### Deploy App Registration & Resource Group Together
- Use [`examples/all-standard`](./examples/all-standard) if you are an Azure super-user who can deploy IAM and computing resources simultaneously in one CLI session.

___

## Troubleshooting

### When Azure and Terraform Get Out Of Sync
Terraform works by comparing:
- your Terraform configuration
    - this means the `.tf` files and variable values you are currently asking Terraform to use
    - for example: `main.tf`, `variables.tf`, `terraform.tfvars`, and the configuration Terraform evaluates when you run `terraform plan -out tfplans/full.tfplan`
- your local Terraform state file (`terraform.tfstate`)
    - this is Terraform's local record of what it believes it already manages
- the real Azure resources
    - this means what is actually provisioned right now in Azure
    - in practice: what you can see in the Azure Portal, or via `az` CLI commands

Those can drift apart during normal operator workflows. Common causes include:
- a `terraform apply` failing or being interrupted part-way through
- Azure resources being created, changed, or deleted manually in the portal or CLI
- switching between different local worktrees or machines with stale local state
- targeted plans/applies that intentionally update only part of the stack
- deleting Azure resources first and expecting Terraform to infer what happened later

Example:
- your local `terraform.tfstate` might still say `pip-hurdle-lab-bridge` exists with a DNS label
- but the Azure Portal might show that you deleted or changed it manually
- Terraform is then working from stale local assumptions until you refresh or repair state

When this happens, use the lightest repair command that matches the situation.

#### 1. Refresh local state from Azure when the resources still exist
Use this when:
- Azure resources still exist
- Terraform should continue managing them
- local `terraform.tfstate` is stale but not fundamentally missing those resources

Inspect first:
```bash
terraform plan -refresh-only
```

Then persist the refreshed view:
```bash
terraform apply -refresh-only
```

Why:
- Terraform re-reads the real Azure resource state and writes the updated values into `terraform.tfstate`.
- This does not intentionally create or destroy infrastructure.

Concrete Example:
- you changed a Public IP DNS label in Azure
- Terraform still thinks the old label is present
- `terraform apply -refresh-only` updates `terraform.tfstate` so Terraform stops reasoning from the old label

#### 2. Import resources that exist in Azure but are missing from local state
Use this when:
- the Azure resource exists
- Terraform says it wants to create it again
- or Terraform reports `already exists` and asks for import

Example:
```bash
terraform import module.azure_hurdle_lab_infra.azurerm_resource_group.hurdle_lab \
  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP_NAME>
```

Why:
- `refresh-only` can update tracked resources, but it cannot discover completely missing resources and add them back into state.
- `terraform import` tells Terraform which real Azure object a state address should manage.

Concrete example:
- the Azure Portal shows `rg-terraform-labs-2` still exists
- but local `terraform.tfstate` no longer contains that resource
- Terraform then tries to create the resource group again and fails with `already exists`
- `terraform import ...` fixes that by reconnecting the real Azure object to the right Terraform address

#### 3. Do not use `terraform state rm` as a substitute for deletion
Use `terraform state rm` only when you intentionally want Terraform to forget a real resource while leaving it alive.

Why:
- It removes the object from state only.
- It does not destroy anything in Azure.
- It usually makes future drift more confusing unless you are deliberately handing that resource off to some other owner.

Concrete example:
- `terraform state rm module.azure_hurdle_lab_infra.azurerm_public_ip.bridge`
- would make Terraform forget that Public IP
- but the Public IP would still exist in Azure and continue costing money until you delete it separately

#### Practical Repair Order
When unsure, work in this order:
1. `terraform init`
2. `terraform plan -refresh-only`
3. `terraform apply -refresh-only`
4. `terraform plan`

Then:
- if Terraform now wants to recreate resources that already exist in Azure, use `terraform import`

This gives you a simple mental model:
- **refresh** when Azure still has the resource and Terraform just has stale information
- **import** when Azure still has the resource but Terraform has forgotten it entirely

### When a Terraform Operation is Interrupted Halfway Through
Terraform is idempotent for resources tracked in state. If an apply fails midway, Terraform can usually continue from where it stopped.

How this works:
- `terraform.tfstate` in your cloned project directory is the local apply state.
- On the next `terraform plan`/`terraform apply`, Terraform compares config to this state and skips already-managed resources.

Resume safely:
```bash
terraform plan -out resume.tfplan
terraform apply resume.tfplan
```

Important:
- Prefer generating a fresh plan when resuming. Do not rely on an old/stale plan file from before a failure.
- If Azure resources exist but are missing from Terraform state, Terraform may try to recreate them and fail with "already exists". In that case, import the resource into state before re-applying.
