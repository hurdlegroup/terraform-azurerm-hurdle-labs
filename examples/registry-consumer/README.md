# Terraform Registry Consumer Example

This directory is a complete consumer stack for the Terraform Registry module:

- `hurdlegroup/hurdle-labs/azurerm`

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan -out tfplans/full.tfplan
terraform apply tfplans/full.tfplan
```

## Module-Targeted Applies

Infra only:
```bash
terraform plan -target=module.hurdle_labs.module.azure_hurdle_lab_infra -out tfplans/infra.tfplan
terraform apply tfplans/infra.tfplan
```

Identity only:
```bash
terraform plan -target=module.hurdle_labs.module.azure_hurdle_lab_identity -out tfplans/identity.tfplan
terraform apply tfplans/identity.tfplan
```

Replace bridge VM:
```bash
terraform plan -target=module.hurdle_labs.module.azure_hurdle_lab_infra -replace=module.hurdle_labs.module.azure_hurdle_lab_infra.azurerm_linux_virtual_machine.bridge -out tfplans/replace-bridge-vm.tfplan
terraform apply tfplans/replace-bridge-vm.tfplan
```

## Retrieve App Secret Value

This consumer stack re-exports the module output at root. Retrieve with:

```bash
terraform output -raw app_registration_client_secret_value
```
