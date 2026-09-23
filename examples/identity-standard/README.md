# Create Azure App Registration and Role Assignments for Hurdle Labs

Run this configuration as the elevated Entra/RBAC operator after the infrastructure operator has handed over `resource_group_id`.

```bash
cp terraform.example.tfvars terraform.tfvars
# Set resource_group_id to the exact output from when the Hurdle Labs resource group was created
terraform init
terraform validate
terraform plan -out=identity.tfplan
terraform apply identity.tfplan
terraform output -raw app_registration_client_secret_value
```

Store the client secret in your approved secret manager immediately.
