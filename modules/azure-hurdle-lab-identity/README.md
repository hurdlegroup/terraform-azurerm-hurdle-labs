# Deploy Hurdle Labs App Registration in Azure
Creates the Hurdle Labs Entra application registration, service principal, client secret, and Azure RBAC assignments.

Use this submodule directly after the infrastructure module has created the Hurdle Labs resource group. It is intended for an elevated Entra/RBAC operator and should normally have its own Terraform state.

## Usage Instructions
- The complete runnable configuration is [`../../examples/identity-standard`](../../examples/identity-standard).
