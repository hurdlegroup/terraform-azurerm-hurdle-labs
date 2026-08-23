# Terraform Registry Consumer Example

This directory is a complete consumer stack for the Terraform Registry module:

- `hurdlegroup/hurdle-labs/azurerm`

## Usage

```bash
cp terraform.example.tfvars terraform.tfvars
terraform init
terraform validate
terraform plan -out tfplans/full.tfplan
terraform apply tfplans/full.tfplan
```

This example is for a single operator authorised to manage both Azure infrastructure and Entra/RBAC resources. For split-permission customer teams, use the independent [`infra-standard`](../infra-standard) and [`identity-standard`](../identity-standard) examples instead. They use separate states and ordinary `terraform apply` operations.

## Retrieve App Secret Value

This consumer stack re-exports the module output at root. Retrieve with:

```bash
terraform output -raw app_registration_client_secret_value
```
