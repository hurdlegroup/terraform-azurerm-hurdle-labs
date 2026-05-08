# Terraform Azure Labs (Hurdle)

## 1) Architecture and Objectives

### Objective
Provision a repeatable Azure foundation for Hurdle Labs, with a strict separation between identity-plane provisioning and infrastructure-plane provisioning.

### Target Architecture
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
        │   └── Assign domain: COMPANY-NAME-hurdle-bridge.cloudapp.azure.com
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
│   └── Defines connection to Azure Bridge e.g. wss://COMPANY-NAME-hurdle-bridge.cloudapp.azure.com
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

### Module Structure (and Why)
- `modules/azure-hurdle-lab-identity`: app registration, service principal, and RBAC assignments.
- `modules/azure-hurdle-lab-infra`: resource group, networking, NAT, bridge NSG/public IP/NIC/VM.

This separation allows IAM-privileged operators to handle identity resources, while infrastructure operators handle resource deployment without broad Entra permissions.

## 2) Prerequisites

### Tooling Prerequisites
- Azure CLI installed (`az`)
- Terraform installed (`terraform`)
- Azure CLI authenticated and pointed at the correct subscription

```bash
az login
az account list --output table
az account set --subscription "<SUBSCRIPTION_ID_OR_NAME>"
az account show --output table
```

If you use multiple tenants:
```bash
az login --tenant "<TENANT_ID>"
az account set --subscription "<SUBSCRIPTION_ID_OR_NAME>"
```

### Permission Prerequisites
- Identity module execution requires permissions to:
  - Create Entra app registrations and service principals
  - Assign RBAC roles at resource-group and subscription scope
- Infra module execution requires permissions to:
  - Create/update resource-group scoped network and compute resources

In short: identity-plane permissions and infrastructure-plane permissions can be delegated to different operator roles.

### Hurdle Community Compute Gallery Prerequisites
Before provisioning the bridge VM, you must add Hurdle's community gallery to your tenant/subscription. Use these exact gallery details:
- Community gallery name: `hurdle-ec6051c3-68bb-4651-a552-8255caddd442`
- Community gallery title: `hurdlePublicImages`

Critical regional requirement:
- **<ins>You _must_ make `hurdlePublicImages` available in the exact same region as your planned bridge VM.</ins>**
- Example #1: if you set Terraform variable `location = "uksouth"`, then you must make `hurdlePublicImages` available in your Azure tenant's `UK South` region.
- Example #2: You gain learners in a new region and want to reduce lab latency for them. To deploy Hurdle Labs in this new region (e.g. `location = "northeurope"`), you must also make `hurdlePublicImages` available in your Azure tenant's `North Europe` region.

If this step is skipped (or done in a different region), image lookup in `terraform.tfvars.example` will return no result and bridge VM provisioning will fail.

## 3) Deployment Runbook

### Terraform Logging (Optional but Recommended)
To see progress details during slower Terraform operations, prefix commands with `TF_LOG=INFO`:

```bash
TF_LOG=INFO terraform plan -out tfplans/full.tfplan
TF_LOG=INFO terraform apply tfplans/full.tfplan
```

You can also set verbose logging as your shell default so all Terraform commands inherit it:

```bash
echo 'export TF_LOG=INFO' >> ~/.bashrc
echo 'export TF_LOG_PATH="$HOME/terraform.log"' >> ~/.bashrc
source ~/.bashrc

# With `export TF_LOG=INFO` now being global, normal `terraform ...` commands will output verbose logs:
terraform plan -out tfplans/full.tfplan
terraform apply tfplans/full.tfplan
```

If you only want console output and no log file, set only `TF_LOG`.

### Step 1: Copy and Populate `terraform.tfvars`
In your cloned project directory:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Populate at minimum:
- `subscription_id`
- `tenant_id`
- `location`
- `resource_group_name`
- `bridge_subdomain_slug`
- `bridge_admin_username`
- `bridge_vm_size` (recommended minimum: `Standard_D4s_v3`)
- `bridge_technical_contact_email`
- `bridge_lab_secret`
- `bridge_source_image_id`
- `bridge_ssh_public_key`
- `bridge_ssh_allowed_cidrs`

Critical check:
- `bridge_ssh_allowed_cidrs` must include your workplace VPN/public egress CIDR, or SSH to the bridge VM will fail.

### Step 2: Initialize Terraform
```bash
terraform init
```

### Step 3: Validate the Configuration
```bash
terraform validate
```

### Step 4 (Approach A): Generate and Apply the Entire Terraform Plan
```bash
terraform plan -out tfplans/full.tfplan
terraform apply tfplans/full.tfplan
```

### Step 4 (Approach B): Generate and Apply Each Terraform Module Separately
By default, the root stack plans/applies both modules. If you need to execute only one side, use `-target`.

Infra module only:
```bash
terraform plan -target=module.azure_hurdle_lab_infra -out tfplans/infra.tfplan
terraform apply tfplans/infra.tfplan
```

Identity module only:
```bash
terraform plan -target=module.azure_hurdle_lab_identity -out tfplans/identity.tfplan
terraform apply tfplans/identity.tfplan
```

Important:
- If you apply each module separately, you _must_ apply `module.azure_hurdle_lab_infra` first because `module.azure_hurdle_lab_identity` needs the resource group to exist so it can assign the App Registration to it. 
- `-target` is for scoped/exception workflows. For routine changes, prefer full-stack `plan`/`apply`.
- Identity-only execution requires `resource_group_id` from the infra module, so infra state/resources must already exist.

## 4) Troubleshooting

### Partial Apply or Interrupted Run
Terraform is idempotent for resources tracked in state. If an apply fails midway, Terraform can usually continue from where it stopped.

How this works:
- `terraform.tfstate` in your cloned project directory is the local apply state.
- On the next `terraform plan`/`terraform apply`, Terraform compares config to this state and skips already-managed resources.

Resume safely:
```bash
terraform plan -out tfplans/resume.tfplan
terraform apply tfplans/resume.tfplan
```

Important:
- Prefer generating a fresh plan when resuming. Do not rely on an old/stale plan file from before a failure.
- If Azure resources exist but are missing from Terraform state, Terraform may try to recreate them and fail with "already exists". In that case, import the resource into state before re-applying.

## 5) How to Validate the Deployment

Use these checks to verify that the deployed bridge VM is reachable and that guacws was configured and started correctly:

```bash
ssh "$(terraform output -raw bridge_admin_username)"@"$(terraform output -raw bridge_public_ip_address)" -i ~/.ssh/azure_hurdle_lab_bridge_ed25519
sudo cat /etc/guacws/appsettings.Production.json
sudo supervisorctl status guacws
```

Expected result:
- `/etc/guacws/appsettings.Production.json` exists with your configured domain, email, and lab secret values.
- `supervisorctl status guacws` reports `RUNNING`.

## 6) How to Replace the Bridge VM

You may need to replace the bridge VM when re-specing it (for example, changing VM size/CPU/RAM) or when you need first-boot provisioning to run again on a fresh instance.

```bash
rm -f tfplans/replace-bridge-vm.tfplan
terraform plan -target=module.azure_hurdle_lab_infra -replace=module.azure_hurdle_lab_infra.azurerm_linux_virtual_machine.bridge -out tfplans/replace-bridge-vm.tfplan
terraform apply tfplans/replace-bridge-vm.tfplan
```

After replacement, re-run the checks in `5) How to Validate the Deployment`.

## Notes
- Runtime behavior: the bridge VM is persistent, while lab VMs are ephemeral and created by Hurdle sessions.
- First boot behavior: cloud-init writes `/etc/guacws/appsettings.Production.json`, sets `guacd:guacd` ownership, and runs `supervisorctl restart guacws`.
- If `terraform apply` fails, copy the exact error plus `az account show` output (redact IDs as needed) when requesting support.
- Keep `terraform.tfvars` environment-specific and uncommitted.
- Use `terraform.tfvars.example` as the reusable, documented template for operators.
