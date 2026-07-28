# Infrastructure Consumer Example

This is the recommended first state for split-permission deployments. It deploys only the Hurdle Labs Azure infrastructure and outputs the resource group ID required by the identity operator.

```bash
cp terraform.example.tfvars terraform.tfvars
terraform init
terraform validate
terraform plan -out=infra.tfplan
terraform apply infra.tfplan
terraform output -raw resource_group_id
```

## Usage Instructions
1. Plan a Bridge Web Domain and Retrieve a Hurdle Bridge Secret
    - Establish what `<bridge_subdomain>.AZURE_REGION.cloudapp.azure.com` domain you want to use.
    - Go to https://manage.hurdle.live/lab/bridges/new and enter the Bridge domain you want to use, with a WebSocket protocol prefix. For example:`wss://COMPANY-NAME-hurdle-bridge.AZURE_REGION.cloudapp.azure.com`.
    - Hurdle will automatically email you a Bridge Secret. You must paste this alphanumeric string into Terraform variable `bridge_lab_secret`.
2. Load the Bridge's URL (`bridge_public_fqdn` from `./terraform.tfstate`) in your web browser. You should see a GuacWS server welcome page like this:
   ![Screenshot of GuacWS holding page loaded in a web browser](https://raw.githubusercontent.com/hurdlegroup/terraform-azurerm-hurdle-labs/6aecb2a11709ccac7a0e164b4a771fc490a241aa/docs/images/screenshot-guacws-holding-page.png)