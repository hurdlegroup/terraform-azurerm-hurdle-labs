# azure-hurdle-lab-infra

Provisions Azure infrastructure for Hurdle Labs:
- resource group
- VNet and subnets
- lab egress (NAT or firewall modes)
- bridge networking and NSG
- persistent bridge VM

## Usage

This submodule is part of `hurdlegroup/hurdle-labs/azurerm` and is typically consumed through the root module.

If you use this submodule directly, you are responsible for wiring identity resources separately (app registration, service principal, and RBAC assignments).

## Inputs and Outputs

See the Terraform Registry Inputs/Outputs tabs for this submodule.
