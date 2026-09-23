# Migrate Existing Bridge Let's Encrypt Certs to Azure Key Vault (Temporary Bodge)

## Why This Exists
This is a pragmatic migration helper for teams moving from direct bridge ingress to `bridge_ingress_mode = "appgw_waf"`.

If your bridge already has a valid TLS certificate on-disk, this workflow lets you temporarily reuse that certificate by importing it into Azure Key Vault so Application Gateway can reference it.

This is intentionally a transitional path, not a long-term certificate lifecycle strategy.

## What It Does
1. Creates a Key Vault in the same resource group as your Terraform state.
2. Copies bridge certificate material from VM and imports it into Key Vault.
3. Provides the Key Vault certificate secret ID for App Gateway Terraform input.

## Prerequisites
- Run from repo root where `terraform.tfstate` exists.
- `az` logged in and pointed at correct subscription.
- `terraform` state has valid outputs for bridge VM details.
- SSH private key for bridge VM (default expected path):
  - `~/.ssh/azure_hurdle_lab_bridge_ed25519`
- Tools installed: `az`, `jq`, `ssh`, `scp`, `openssl`.

## Step 1: Create Key Vault
Example:

```bash
bash examples/migrate-lets-encrypt-to-azure-vault/scripts/create-azure-key-vault.sh \
  --key-vault-name=kv-hurdle-labs \
  --uami-name=uami-hurdle-lab-appgw-kv
```

Expected output includes:
- `KEY_VAULT_NAME=kv-...`
- `RESOURCE_GROUP_NAME=rg-...`
- `UAMI_ID=/subscriptions/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/...`

## Step 2: Copy Bridge Cert into Key Vault
```bash
bash examples/migrate-lets-encrypt-to-azure-vault/scripts/copy-lets-encrypt-to-azure-vault.sh \
  --azure-vault-name=...
```

Script options:
- `--azure-vault-name=<name>` (required target Key Vault name)
- `--ssh-key-path=<path>` (override SSH key path)
- `--azure-vault-cert-name=<name>` (default: `hurdle-bridge-tls-certificate`)

Example:
```bash
bash examples/migrate-lets-encrypt-to-azure-vault/scripts/copy-lets-encrypt-to-azure-vault.sh \
  --azure-vault-name=kv-hurdle-labs \
  --ssh-key-path=~/.ssh/azure_hurdle_lab_bridge_ed25519 \
  --azure-vault-cert-name=hurdle-bridge-tls-cert-temporary
```

## Step 3: Use in App Gateway Variables
Set Terraform variable (when `bridge_ingress_mode = "appgw_waf"`):
```hcl
bridge_appgw_tls_key_vault_secret_id = "<KEY_VAULT_CERT_SECRET_ID>"
bridge_appgw_key_vault_uami_id       = "<UAMI_ID_FROM_STEP_1>"
```

Retrieve the imported cert secret id:
```bash
az keyvault certificate show \
  --vault-name="<KV_NAME>" \
  --name="<CERT_NAME>" \
  --query sid -o tsv
```

## Caveats
- This is a migration shortcut. Do not treat it as your permanent certificate automation strategy.
- Imported cert expiration remains tied to the original certificate issuance.
- Bridge certificate renewal and Key Vault re-import are separate operations unless you build automation.
- Key Vault access and Application Gateway identity permissions must still be configured correctly.
