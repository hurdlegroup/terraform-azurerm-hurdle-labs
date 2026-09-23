#!/usr/bin/env bash
set -euo pipefail

# SSH into bridge VM, discover current TLS certificate material,
# package/import into Azure Key Vault certificate object.

WORKDIR="${WORKDIR:-$(pwd)}"
cd "$WORKDIR"

SSH_KEY_PATH="$HOME/.ssh/azure_hurdle_lab_bridge_ed25519"
AZURE_VAULT_NAME=""
AZURE_VAULT_CERT_NAME="hurdle-bridge-tls-certificate"
SSH_VERBOSE=false

usage() {
  cat <<USAGE
Usage:
  bash examples/migrate-lets-encrypt-to-azure-vault/scripts/copy-lets-encrypt-to-azure-vault.sh [options]

Options:
  --azure-vault-name=<name>     Target Azure Key Vault name for certificate import.
                                Required.
  --ssh-key-path=<path>         SSH private key path for bridge VM access.
                                Default: ~/.ssh/azure_hurdle_lab_bridge_ed25519
  --azure-vault-cert-name=<name>
                                Certificate object name to create/update in Key Vault.
                                Default: hurdle-bridge-tls-certificate
  --ssh-verbose                 Enable SSH/SCP protocol debug output.
  -h, --help                    Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --azure-vault-name=*)
      AZURE_VAULT_NAME="${1#*=}"
      shift
      ;;
    --ssh-key-path=*)
      SSH_KEY_PATH="${1#*=}"
      shift
      ;;
    --azure-vault-cert-name=*)
      AZURE_VAULT_CERT_NAME="${1#*=}"
      shift
      ;;
    --ssh-verbose)
      SSH_VERBOSE=true
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

if [[ -z "$AZURE_VAULT_NAME" ]]; then
  echo "[fatal] Missing required option: --azure-vault-name=<name>"
  usage
  exit 1
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "[fatal] Missing command: $1"; exit 1; }
}

need_cmd az
need_cmd jq
need_cmd ssh
need_cmd scp
need_cmd openssl

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
BRIDGE_IP="$(get_tf_output bridge_public_ip_address)"
BRIDGE_USER="$(get_tf_output bridge_admin_username)"
BRIDGE_FQDN="$(get_tf_output bridge_public_fqdn)"

if [[ -z "$RG_NAME" ]]; then RG_NAME="$(get_state_value '.outputs.resource_group_name.value')"; fi
if [[ -z "$BRIDGE_IP" ]]; then BRIDGE_IP="$(get_state_value '.outputs.bridge_public_ip_address.value')"; fi
if [[ -z "$BRIDGE_USER" ]]; then BRIDGE_USER="$(get_state_value '.outputs.bridge_admin_username.value')"; fi
if [[ -z "$BRIDGE_FQDN" ]]; then BRIDGE_FQDN="$(get_state_value '.outputs.bridge_public_fqdn.value')"; fi

if [[ -z "$RG_NAME" || -z "$BRIDGE_IP" || -z "$BRIDGE_USER" || -z "$BRIDGE_FQDN" ]]; then
  echo "[fatal] Missing one of RG_NAME/BRIDGE_IP/BRIDGE_USER/BRIDGE_FQDN from terraform output/state"
  exit 1
fi

KV_NAME="$AZURE_VAULT_NAME"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FULLCHAIN_REMOTE="/tmp/${AZURE_VAULT_CERT_NAME}.fullchain.pem"
PRIVKEY_REMOTE="/tmp/${AZURE_VAULT_CERT_NAME}.privkey.pem"
PFX_REMOTE="/tmp/${AZURE_VAULT_CERT_NAME}.source.pfx"
FULLCHAIN_LOCAL="$TMP_DIR/fullchain.pem"
PRIVKEY_LOCAL="$TMP_DIR/privkey.pem"
PFX_LOCAL="$TMP_DIR/$AZURE_VAULT_CERT_NAME.pfx"

SSH_OPTS=(
  -o StrictHostKeyChecking=accept-new
  -o BatchMode=yes
  -o ServerAliveInterval=15
  -o ServerAliveCountMax=3
  -i "$SSH_KEY_PATH"
)
SCP_OPTS=(
  -o StrictHostKeyChecking=accept-new
  -o BatchMode=yes
  -i "$SSH_KEY_PATH"
)

if [[ "$SSH_VERBOSE" == true ]]; then
  SSH_OPTS=(-vvv "${SSH_OPTS[@]}")
  SCP_OPTS=(-vvv "${SCP_OPTS[@]}")
fi

log "Bridge user: $BRIDGE_USER"
log "Bridge IP: $BRIDGE_IP"
log "Bridge FQDN (terraform): $BRIDGE_FQDN"
log "Target Key Vault: $KV_NAME"
log "Target Key Vault certificate name: $AZURE_VAULT_CERT_NAME"
log "SSH key path: $SSH_KEY_PATH"

log "Step 1/7: Discover certificate material on bridge"
set +e
DISCOVERY_OUTPUT="$(ssh "${SSH_OPTS[@]}" "$BRIDGE_USER@$BRIDGE_IP" "sudo bash -s" 2>&1 <<'REMOTE_DISCOVERY'
set -euo pipefail

latest_renewal=""
if ls /etc/letsencrypt/renewal/*.conf >/dev/null 2>&1; then
  latest_renewal="$(ls -1t /etc/letsencrypt/renewal/*.conf | head -n1)"
  cert_path="$(grep -E '^cert\s*=' "$latest_renewal" | head -n1 | cut -d= -f2- | xargs || true)"
  privkey_path="$(grep -E '^privkey\s*=' "$latest_renewal" | head -n1 | cut -d= -f2- | xargs || true)"
  if [[ -n "$cert_path" && -n "$privkey_path" && -f "$cert_path" && -f "$privkey_path" ]]; then
    echo "METHOD=renewal_conf"
    echo "FULLCHAIN_PATH=$cert_path"
    echo "PRIVKEY_PATH=$privkey_path"
    exit 0
  fi
fi

if ls /etc/letsencrypt/live/*/fullchain.pem >/dev/null 2>&1; then
  candidate="$(ls -1t /etc/letsencrypt/live/*/fullchain.pem | head -n1)"
  candidate_dir="$(dirname "$candidate")"
  candidate_key="$candidate_dir/privkey.pem"
  if [[ -f "$candidate" && -f "$candidate_key" ]]; then
    echo "METHOD=live_dir_fallback"
    echo "FULLCHAIN_PATH=$candidate"
    echo "PRIVKEY_PATH=$candidate_key"
    exit 0
  fi
fi

if ls /home/guacd/.dotnet/corefx/cryptography/x509stores/my/*.pfx >/dev/null 2>&1; then
  pfx_candidate="$(ls -1t /home/guacd/.dotnet/corefx/cryptography/x509stores/my/*.pfx | head -n1)"
  if [[ -f "$pfx_candidate" ]]; then
    echo "METHOD=dotnet_store_pfx"
    echo "PFX_PATH=$pfx_candidate"
    exit 0
  fi
fi

if [[ -f /etc/guacws/appsettings.Production.json ]]; then
  domain="$(python3 - <<'PY' 2>/dev/null || true
import json
p='/etc/guacws/appsettings.Production.json'
try:
    with open(p, 'r', encoding='utf-8') as f:
        d=json.load(f)
    dom=(d.get('Server',{}).get('LetsEncrypt',{}).get('Domains') or [''])[0]
    print(dom)
except Exception:
    pass
PY
)"
  if [[ -n "${domain:-}" ]]; then
    fc="/etc/letsencrypt/live/$domain/fullchain.pem"
    pk="/etc/letsencrypt/live/$domain/privkey.pem"
    if [[ -f "$fc" && -f "$pk" ]]; then
      echo "METHOD=guacws_domain_fallback"
      echo "FULLCHAIN_PATH=$fc"
      echo "PRIVKEY_PATH=$pk"
      exit 0
    fi
  fi
fi

echo "METHOD=not_found"
exit 1
REMOTE_DISCOVERY
)"
DISCOVERY_STATUS=$?
set -e

if [[ $DISCOVERY_STATUS -ne 0 ]]; then
  echo "[fatal] SSH discovery failed with exit code $DISCOVERY_STATUS"
  echo "$DISCOVERY_OUTPUT"
  exit $DISCOVERY_STATUS
fi

echo "$DISCOVERY_OUTPUT"
DISCOVERY_METHOD="$(echo "$DISCOVERY_OUTPUT" | awk -F= '/^METHOD=/{print $2}' | tail -n1)"
DISCOVERED_FULLCHAIN="$(echo "$DISCOVERY_OUTPUT" | awk -F= '/^FULLCHAIN_PATH=/{print $2}' | tail -n1)"
DISCOVERED_PRIVKEY="$(echo "$DISCOVERY_OUTPUT" | awk -F= '/^PRIVKEY_PATH=/{print $2}' | tail -n1)"
DISCOVERED_PFX="$(echo "$DISCOVERY_OUTPUT" | awk -F= '/^PFX_PATH=/{print $2}' | tail -n1)"

if [[ "$DISCOVERY_METHOD" == "dotnet_store_pfx" ]]; then
  if [[ -z "$DISCOVERED_PFX" ]]; then
    echo "[fatal] dotnet_store_pfx selected but PFX_PATH is empty"
    exit 1
  fi

  log "Discovery method: $DISCOVERY_METHOD"
  log "Discovered PFX path: $DISCOVERED_PFX"

  log "Step 2/7: Stage discovered source PFX on bridge /tmp"
  ssh "${SSH_OPTS[@]}" "$BRIDGE_USER@$BRIDGE_IP" \
    "set -euo pipefail; sudo ls -l '$DISCOVERED_PFX'; sudo cp '$DISCOVERED_PFX' '$PFX_REMOTE'; sudo chown $BRIDGE_USER:$BRIDGE_USER '$PFX_REMOTE'; ls -l '$PFX_REMOTE'"

  log "Step 3/7: SCP source PFX -> $PFX_LOCAL"
  scp "${SCP_OPTS[@]}" "$BRIDGE_USER@$BRIDGE_IP:$PFX_REMOTE" "$PFX_LOCAL"
  ls -l "$PFX_LOCAL"

  log "Step 4/7: Validate source PFX can be opened"
  openssl pkcs12 -in "$PFX_LOCAL" -nokeys -passin pass: >/dev/null

  log "Step 5/7: Remove staged /tmp source PFX from bridge"
  ssh "${SSH_OPTS[@]}" "$BRIDGE_USER@$BRIDGE_IP" "rm -f '$PFX_REMOTE' && echo cleaned" || true

  log "Step 6/7: Re-export PFX with import password"
  openssl pkcs12 -in "$PFX_LOCAL" -nodes -passin pass: \
    | openssl pkcs12 -export -out "$PFX_LOCAL.repack.pfx" -passout pass:
  mv -f "$PFX_LOCAL.repack.pfx" "$PFX_LOCAL"
  ls -l "$PFX_LOCAL"

  log "Step 7/7: Import certificate into Azure Key Vault"
  az keyvault certificate import \
    --vault-name "$KV_NAME" \
    --name "$AZURE_VAULT_CERT_NAME" \
    --file "$PFX_LOCAL" \
    --password "" \
    --output table

  echo
  log "Done"
  echo "KEY_VAULT_NAME=$KV_NAME"
  echo "CERTIFICATE_NAME=$AZURE_VAULT_CERT_NAME"
  echo "BRIDGE_FQDN=$BRIDGE_FQDN"
  echo "DISCOVERY_METHOD=$DISCOVERY_METHOD"
  echo "DISCOVERED_PFX_PATH=$DISCOVERED_PFX"
  exit 0
fi

if [[ -z "$DISCOVERED_FULLCHAIN" || -z "$DISCOVERED_PRIVKEY" ]]; then
  echo "[fatal] Could not discover valid cert/key paths on bridge"
  exit 1
fi

log "Discovery method: ${DISCOVERY_METHOD:-unknown}"
log "Discovered fullchain path: $DISCOVERED_FULLCHAIN"
log "Discovered privkey path: $DISCOVERED_PRIVKEY"

log "Step 2/7: Stage discovered cert files on bridge /tmp"
ssh "${SSH_OPTS[@]}" "$BRIDGE_USER@$BRIDGE_IP" \
  "set -euo pipefail; sudo ls -l '$DISCOVERED_FULLCHAIN' '$DISCOVERED_PRIVKEY'; sudo cp '$DISCOVERED_FULLCHAIN' '$FULLCHAIN_REMOTE'; sudo cp '$DISCOVERED_PRIVKEY' '$PRIVKEY_REMOTE'; sudo chown $BRIDGE_USER:$BRIDGE_USER '$FULLCHAIN_REMOTE' '$PRIVKEY_REMOTE'; ls -l '$FULLCHAIN_REMOTE' '$PRIVKEY_REMOTE'"

log "Step 3/7: SCP fullchain.pem -> $FULLCHAIN_LOCAL"
scp "${SCP_OPTS[@]}" "$BRIDGE_USER@$BRIDGE_IP:$FULLCHAIN_REMOTE" "$FULLCHAIN_LOCAL"
ls -l "$FULLCHAIN_LOCAL"

log "Step 4/7: SCP privkey.pem -> $PRIVKEY_LOCAL"
scp "${SCP_OPTS[@]}" "$BRIDGE_USER@$BRIDGE_IP:$PRIVKEY_REMOTE" "$PRIVKEY_LOCAL"
ls -l "$PRIVKEY_LOCAL"

log "Step 5/7: Remove staged /tmp files from bridge"
ssh "${SSH_OPTS[@]}" "$BRIDGE_USER@$BRIDGE_IP" "rm -f '$FULLCHAIN_REMOTE' '$PRIVKEY_REMOTE' && echo cleaned" || true

log "Step 6/7: Build PKCS#12 bundle -> $PFX_LOCAL"
openssl pkcs12 -export \
  -inkey "$PRIVKEY_LOCAL" \
  -in "$FULLCHAIN_LOCAL" \
  -out "$PFX_LOCAL" \
  -passout pass:
ls -l "$PFX_LOCAL"

log "Step 7/7: Import certificate into Azure Key Vault"
az keyvault certificate import \
  --vault-name "$KV_NAME" \
  --name "$AZURE_VAULT_CERT_NAME" \
  --file "$PFX_LOCAL" \
  --password "" \
  --output table

echo
log "Done"
echo "KEY_VAULT_NAME=$KV_NAME"
echo "CERTIFICATE_NAME=$AZURE_VAULT_CERT_NAME"
echo "BRIDGE_FQDN=$BRIDGE_FQDN"
echo "DISCOVERY_METHOD=${DISCOVERY_METHOD:-unknown}"
echo "DISCOVERED_FULLCHAIN_PATH=$DISCOVERED_FULLCHAIN"
echo "DISCOVERED_PRIVKEY_PATH=$DISCOVERED_PRIVKEY"
