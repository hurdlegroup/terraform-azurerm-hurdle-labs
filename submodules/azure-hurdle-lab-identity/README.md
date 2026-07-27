# azure-hurdle-lab-identity

Provisions Azure Entra identity resources for Hurdle Labs:
- app registration
- service principal
- app registration client secret
- RBAC role assignments required by Hurdle

## Usage

This submodule is part of `hurdlegroup/hurdle-labs/azurerm` and is typically consumed through the root module.

If you use this submodule directly, ensure the infrastructure resource group already exists and pass its ID for role assignment scope.

## Inputs and Outputs

See the Terraform Registry Inputs/Outputs tabs for this submodule.
