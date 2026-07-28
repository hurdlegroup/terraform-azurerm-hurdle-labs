# Advanced Egress for Lab Machines

### Lab Machine Egress Modes Supported by This Module
This module supports three egress modes for the `lab-machines` subnet:

- `machines_egress_mode = "nat"|null`
  Default mode. Lab machines egress through module-managed NAT Gateway.
  See [`examples/infra-standard`](../../examples/infra-standard).
  ```text
  Lab Machine VM
  └─→ snet-hurdle-lab-machines
      └─→ nat-hurdle-lab-machines
          └─→ pip-nat-hurdle-lab-machines
              └─→ Public Internet
  ```
- `machines_egress_mode = "firewall_module_provisioned"`
  Module creates an Azure Firewall in the same Hurdle labs resource group and routes lab-machines egress through it.
  Baseline allow rules are included for typical endpoint behavior (DNS, NTP, ICMP, HTTP, HTTPS).
  ```text
  Azure Subscription
  └── Resource Group: rg-hurdle-labs
      ├── Public IP: pip-fw-hurdle-lab-machines-egress
      ├── vnet-hurdle-lab
      │   └── snet-hurdle-lab-machines
      │       └── Lab Machine VMs (ephemeral)
      │   └── AzureFirewallSubnet
      │       └── fw-hurdle-lab-machines-egress
      │
      └── rt-hurdle-lab-machines-egress
          └── 0.0.0.0/0 -> <machines_managed_firewall_subnet_cidr>
  
  Lab Machine VM
  └─→ snet-hurdle-lab-machines
      └─→ rt-hurdle-lab-machines-egress (0.0.0.0/0 ⭢ firewall private IP)
          └─→ fw-hurdle-lab-machines-egress (AzureFirewallSubnet)
              └─→ pip-fw-hurdle-lab-machines-egress
                  └─→ Public Internet
  ```
- `machines_egress_mode = "firewall_customer_existing"`
  Module routes lab-machines egress to an existing customer-managed, **Bring-Your-Own (BYO)** firewall private IP.
    ```text
    Azure Subscription
    ├── Resource Group: rg-hurdle-labs
    │   ├── vnet-hurdle-lab
    │   │   └── snet-hurdle-lab-machines
    │   │       └── Lab Machine VMs (ephemeral)
    │   │
    │   └── rt-hurdle-lab-machines-egress
    │       └── 0.0.0.0/0 -> <machines_byo_firewall_private_ip>
    │
    └── Resource Group: rg-your-existing-azure-assets
        ├── pip-fw-existing
        └── vnet-firewall-existing
            └── AzureFirewallSubnet
            └── fw-existing (Paste your Firewall's private IP into TF variable `machines_byo_firewall_private_ip`)
    
    Required cross-VNet links:
    - vnet-hurdle-lab <-> vnet-firewall-existing (bidirectional VNet peering)
    - both peerings: allowVirtualNetworkAccess=true, allowForwardedTraffic=true

    Lab Machine VM
    └─→ snet-hurdle-lab-machines
        └─→ machines_byo_route_table_* (or module-created machines route table)
            └─→ customer existing firewall private IP
                └─→ customer existing firewall public egress
                    └─→ Public Internet
    ```

### Why Enterprises Use Advanced Egress
Some enterprise customers require outbound traffic controls beyond subnet NAT. Typical requirements include:
- central outbound inspection
- domain/IP allow-listing
- egress logging and retention
- mandatory routing through a security-managed firewall

### CLI Runbook: Switching Egress Mode
1. Update your variables file:
    - `machines_egress_mode = "nat"` or
    - `machines_egress_mode = "firewall_module_provisioned"` or
    - `machines_egress_mode = "firewall_customer_existing"`
2. Set mode-specific variables:
    - for `firewall_module_provisioned`: set `machines_managed_firewall_*` variables as needed.
    - for `firewall_customer_existing`: set `machines_byo_firewall_private_ip` and optionally `machines_byo_route_table_*`.
3. Generate and apply the plan:
   ```bash
   terraform plan -out machines-egress-switch.tfplan
   terraform apply machines-egress-switch.tfplan
   ```
4. Confirm Terraform outputs reflect your target state:
   ```bash
   terraform output -raw machines_egress_mode
   terraform output machines_route_table_id
   terraform output machines_nat_gateway_id
   terraform output machines_managed_firewall_id
   terraform output machines_managed_firewall_private_ip
   ```

### Azure Portal Verification Checklist
After apply, verify in Azure portal:
- `vnet-hurdle-lab` -> `snet-hurdle-lab-machines`:
    - in `nat` mode: NAT gateway association is present.
    - in firewall modes: route table association is present.
- Route table (for firewall modes):
    - default route `0.0.0.0/0` exists.
    - next hop type is `Virtual appliance`.
    - next hop IP matches managed firewall private IP or your BYO firewall private IP.
- For `firewall_module_provisioned`:
    - `AzureFirewallSubnet` exists.
    - managed firewall and its public IP are in `Succeeded` state.
    - firewall network rule collection `machines-baseline-network` exists with:
        - `allow-dns` (TCP/UDP 53 to `*`)
        - `allow-ntp` (UDP 123 to `*`)
        - `allow-icmp` (ICMP to `*`)
    - firewall application rule collection `machines-web-browsing` exists with:
        - `allow-http-https` (HTTP 80 and HTTPS 443 to `*`)

### Hurdle Conference Acceptance Tests
After switching modes, run these acceptance checks:
1. In Hurdle Dashboard, create a new test lab session (do not rely on an old cached session).
2. Join as any Hurdle Lab User (trainer or learner) and confirm lab machine launches and reaches desktop.
3. Confirm user internet egress through the configured firewall path:
    - inside the user lab machine, open a web browser
    - browse to a public HTTPS site (for example, `https://www.google.com`)
    - confirm page load succeeds and normal outbound browsing works
4. Confirm bridge connectivity remains healthy:
    - browser can load `https://<bridge_public_fqdn>/`
    - websocket session establishes in Hurdle Conference.
5. Run at least one in-lab outbound test from the Lab Machine VM (for example DNS + HTTPS reachability) and confirm it behaves per policy.
6. Re-run once with a second fresh Lab Machine VM to ensure behavior is repeatable.

### Operational Caveats
- Switching modes in-place is supported, but expect short-lived outbound interruption for active lab machines during route association changes.
- `firewall_module_provisioned` requires free address space for `AzureFirewallSubnet`.
- `firewall_customer_existing` requires a valid return path and firewall policy that permits required traffic.
