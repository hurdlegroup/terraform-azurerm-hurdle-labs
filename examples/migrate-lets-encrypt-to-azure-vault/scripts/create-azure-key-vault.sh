#!/usr/bin/env bash
set -euo pipefail

# Creates an Azure Key Vault in the same resource group as the current Terraform state,
# creates a user-assigned managed identity, and grants it vault secret read access.

WORKDIR="${WORKDIR:-$(pwd)}"
cd "$WORKDIR"

KEY_VAULT_NAME=""
UAMI_NAME=""

usage() {
  cat <<USAGE
Usage:
  bash examples/migrate-lets-encrypt-to-azure-vault/scripts/create-azure-key-vault.sh \
    --key-vault-name=<name> \
    --uami-name=<name>

Required arguments:
  --key-vault-name=<name>  Explicit Key Vault name to create/use (for iterative create/delete workflows).
  --uami-name=<name>       User-assigned managed identity name to create/use for App Gateway Key Vault access.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key-vault-name=*)
      KEY_VAULT_NAME="${1#*=}"
      shift
      ;;
    --uami-name=*)
      UAMI_NAME="${1#*=}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[fatal] Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$KEY_VAULT_NAME" ]]; then
  echo "[fatal] Missing required option: --key-vault-name=<name>"
  usage
  exit 1
fi

if [[ -z "$UAMI_NAME" ]]; then
  echo "[fatal] Missing required option: --uami-name=<name>"
  usage
  exit 1
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "[fatal] Missing command: $1"; exit 1; }
}

need_cmd az
need_cmd jq

log() {
  printf '[%s] %s\n' "$(date -u +%H:%M:%SZ)" "$*"
}

get_tf_output() {
  local name="$1"
  terraform output -raw "$name" 2>/dev/null || true
}

get_state_value() {
  local jq_expr="$1"
  jq -r "$jq_expr // empty" terraform.tfstate 2>/dev/null || true
}

RG_NAME="$(get_tf_output resource_group_name)"
LOCATION="$(get_tf_output location)"

if [[ -z "$RG_NAME" ]]; then
  RG_NAME="$(get_state_value '.outputs.resource_group_name.value')"
fi

if [[ -z "$LOCATION" ]]; then
  LOCATION="$(get_state_value '.resources[] | select(.type=="azurerm_resource_group" and .name=="hurdle_lab") | .instances[0].attributes.location')"
fi

if [[ -z "$RG_NAME" ]]; then
  echo "[fatal] Could not resolve resource group name from terraform output or terraform.tfstate"
  exit 1
fi

if [[ -z "$LOCATION" ]]; then
  echo "[fatal] Could not resolve Azure location from terraform output or terraform.tfstate"
  exit 1
fi

KV_NAME="$KEY_VAULT_NAME"
KV_NAME="$(echo "$KV_NAME" | tr '[:upper:]' '[:lower:]')"
KV_NAME="$(echo "$KV_NAME" | sed -E 's/[^a-z0-9-]//g' | sed -E 's/^-+//; s/-+$//')"

if (( ${#KV_NAME} < 3 )); then
  echo "[fatal] Derived Key Vault name '$KV_NAME' is too short"
  exit 1
fi

if (( ${#KV_NAME} > 24 )); then
  KV_NAME="${KV_NAME:0:24}"
  KV_NAME="$(echo "$KV_NAME" | sed -E 's/-+$//')"
fi

if [[ "$KV_NAME" == -* || "$KV_NAME" == *- ]]; then
  echo "[fatal] Derived Key Vault name '$KV_NAME' starts/ends with '-'"
  exit 1
fi

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"

log "Using subscription: $SUBSCRIPTION_ID"
log "Using tenant: $TENANT_ID"
log "Resource group: $RG_NAME"
log "Location: $LOCATION"
log "Key Vault name: $KV_NAME"
log "UAMI name: $UAMI_NAME"

log "Ensuring Key Vault exists"
az keyvault create \
  --name="$KV_NAME" \
  --resource-group="$RG_NAME" \
  --location="$LOCATION" \
  --enable-rbac-authorization=true \
  --output=table

KV_ID="$(az keyvault show --name="$KV_NAME" --resource-group="$RG_NAME" --query id -o tsv)"
CURRENT_USER_UPN="$(az account show --query user.name -o tsv)"
CURRENT_USER_OBJECT_ID="$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)"

if [[ -n "$KV_ID" && -n "$CURRENT_USER_OBJECT_ID" ]]; then
  log "Attempting to grant current user Key Vault Administrator on vault scope"
  set +e
  az role assignment create \
    --assignee-object-id="$CURRENT_USER_OBJECT_ID" \
    --assignee-principal-type=User \
    --role="Key Vault Administrator" \
    --scope="$KV_ID" \
    --output=none
  ASSIGN_EXIT=$?
  set -e

  if [[ $ASSIGN_EXIT -eq 0 ]]; then
    log "Granted Key Vault Administrator to: $CURRENT_USER_UPN"
  else
    printf '\033[31m[error] Could not grant Key Vault Administrator to current user (%s).\033[0m\n' "$CURRENT_USER_UPN"
    printf '\033[31m[error] Without that role, you likely cannot run examples/migrate-lets-encrypt-to-azure-vault/scripts/copy-lets-encrypt-to-azure-vault.sh successfully.\033[0m\n'
  fi
else
  printf '\033[31m[error] Could not resolve current user object ID for RBAC assignment.\033[0m\n'
  printf '\033[31m[error] Current user may not be able to run examples/migrate-lets-encrypt-to-azure-vault/scripts/copy-lets-encrypt-to-azure-vault.sh without manual role assignment.\033[0m\n'
fi

log "Ensuring UAMI exists"
az identity create \
  --name="$UAMI_NAME" \
  --resource-group="$RG_NAME" \
  --location="$LOCATION" \
  --output=table

UAMI_ID="$(az identity show --name="$UAMI_NAME" --resource-group="$RG_NAME" --query id -o tsv)"
UAMI_PRINCIPAL_ID="$(az identity show --name="$UAMI_NAME" --resource-group="$RG_NAME" --query principalId -o tsv)"

if [[ -z "$UAMI_ID" || -z "$UAMI_PRINCIPAL_ID" ]]; then
  echo "[fatal] Could not resolve UAMI id/principalId after create/show"
  exit 1
fi

log "Attempting to grant UAMI Key Vault Secrets User on vault scope"
set +e
az role assignment create \
  --assignee-object-id="$UAMI_PRINCIPAL_ID" \
  --assignee-principal-type=ServicePrincipal \
  --role="Key Vault Secrets User" \
  --scope="$KV_ID" \
  --output=none
UAMI_ASSIGN_EXIT=$?
set -e

if [[ $UAMI_ASSIGN_EXIT -eq 0 ]]; then
  log "Granted Key Vault Secrets User to UAMI principal"
else
  printf '\033[31m[error] Could not grant Key Vault Secrets User to UAMI (%s).\033[0m\n' "$UAMI_NAME"
  printf '\033[31m[error] App Gateway may fail to read bridge_appgw_tls_key_vault_secret_id until this role is granted.\033[0m\n'
fi

echo
log "Done"
echo "KEY_VAULT_NAME=$KV_NAME"
echo "RESOURCE_GROUP_NAME=$RG_NAME"
echo "UAMI_NAME=$UAMI_NAME"
echo "UAMI_ID=$UAMI_ID"
echo "UAMI_PRINCIPAL_ID=$UAMI_PRINCIPAL_ID"
