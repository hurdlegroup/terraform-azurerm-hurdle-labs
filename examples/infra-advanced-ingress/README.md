# Advanced Ingress for Lab Bridge

### Lab Bridge Ingress Modes Supported by This Module
This module supports two egress modes for the `lab-bridge` subnet:
- `bridge_ingress_mode = "direct_pip"|null`
  Default mode. Internet traffic reaches bridge via a Public IP.
  See [`examples/infra-standard`](../../examples/infra-standard).
    ```text
    Azure Subscription
    └── Resource Group: rg-hurdle-labs
        ├── Public IP: pip-hurdle-lab-bridge (public ingress)
        ├── Network Security Group: nsg-hurdle-lab-bridge
        │   ├── attached to vm-hurdle-lab-bridge
        │   ├── allow SSH from bridge_ssh_allowed_cidrs
        │   └── allow app ports only from snet-hurdle-lab-edge CIDR
        └── vnet-hurdle-lab
            └── snet-hurdle-lab-bridge
                └── vm-hurdle-lab-bridge
                    ├── Attached pip-hurdle-lab-bridge
                    └── Attached nsg-hurdle-lab-bridge
    
    Public Internet
    └─→ HTTPS/WSS Traffic
        └─→ Public IP
            └─→ Bridge VM
    ```
- `bridge_ingress_mode = "appgw_waf"`
  Module creates an Application Gateway + WAF.
  Internet traffic reaches bridge via managed Application Gateway/WAF.
  Bridge VM remains private-backend behind App Gateway for HTTP/HTTPS app ingress.
  Bridge Public IP remains for SSH operations from `bridge_ssh_allowed_cidrs`.
  See [`../../examples/infra-advanced-ingress`](../../examples/infra-advanced-ingress).
    ```text
    Azure Subscription
    └── Resource Group: rg-hurdle-labs
        ├── Public IP: pip-appgw-hurdle-lab-bridge (public ingress)
        ├── Web Application Firewall: wafp-hurdle-lab-bridge
        ├── Network Security Group: nsg-hurdle-lab-bridge
        │   ├── attached to vm-hurdle-lab-bridge
        │   ├── allow SSH from bridge_ssh_allowed_cidrs
        │   └── allow app ports only from snet-hurdle-lab-edge CIDR
        └── vnet-hurdle-lab
            ├── snet-hurdle-lab-edge
            │   └── Application Gateway: appgw-hurdle-lab-bridge (WAF_v2)
            └── snet-hurdle-lab-bridge
                └── vm-hurdle-lab-bridge (private backend target)
    
    Public Internet
    └─→ HTTPS/WSS Traffic
        └─→ Application Gateway/WAF
            └─→ Bridge VM private IP
    ```

### Why Enterprises Use Advanced Ingress
Some enterprise customers require bridge ingress through a managed edge control plane rather than direct VM public ingress. Typical requirements include:
- central TLS termination
- WAF policy enforcement
- controlled exposure of the bridge backend
- security team ownership of internet-facing entry points

### CLI Runbook: Switching Bridge Ingress Mode
1. Update variables:
    ```bash
    bridge_ingress_mode = "appgw_waf"
    bridge_appgw_tls_key_vault_secret_id = "<KEY_VAULT_CERT_SECRET_ID>"
    bridge_appgw_key_vault_uami_id       = "/subscriptions/<SUB_ID>/resourceGroups/<RG_NAME>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<UAMI_NAME>"
    ```
2. Plan/apply infra module only:
    ```bash
    terraform plan out tfplans/bridge-ingress-switch.tfplan
    terraform apply tfplans/bridge-ingress-switch.tfplan
    ```

### Azure Portal Verification Checklist
Verify in Azure portal:
- `snet-hurdle-lab-edge` exists and is dedicated to App Gateway.
- `appgw-hurdle-lab-bridge` is `Succeeded` and healthy backend status is green.
- WAF policy is attached to App Gateway.
- `pip-appgw-hurdle-lab-bridge` has a public IP/FQDN.
- Bridge NSG ingress for ports 80/443 is restricted to edge subnet CIDR (not `*`).
- Bridge VM remains SSH reachable only from `bridge_ssh_allowed_cidrs`.

### Hurdle Conference Acceptance Tests
1. Open `https://<bridge_appgw_public_fqdn>/` and confirm bridge holding page behavior.
2. Create/start a fresh Hurdle session.
3. Join from web/desktop app and confirm websocket session establishes.
4. Confirm bridge admin SSH still works from allowed CIDRs.
5. Confirm direct bridge public app ingress is not the primary path in `appgw_waf` mode.

### Operational Caveats
- `appgw_waf` requires free non-overlapping VNet address space for edge subnet.
- Key Vault certificate secret ID must be valid and readable by the user-assigned managed identity attached to Application Gateway.
- App Gateway/WAF provisioning is slower than direct PIP mode.
- Bridge PIP is retained for SSH operations in this profile.
