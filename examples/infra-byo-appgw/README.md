# Use your existing Application Gateway for Lab Bridge traffic

Your organisation may already run a shared Azure Application Gateway and want Hurdle Lab Bridge traffic to pass through it. The Hurdle Terraform module can create its own gateway with `bridge_ingress_mode = "appgw_waf"`, but it cannot attach a Bridge to a gateway you already own. This guide describes two customer-managed workarounds for **Application Gateway v2**. Application Gateway v1 has different backend certificate validation and is outside this guide.

Both routes deploy the Bridge with `bridge_ingress_mode = "direct_pip"`. The module therefore **still creates and attaches a Bridge public IP** and configures the Bridge to obtain a TLS certificate for its Azure DNS name, `<BRIDGE_FQDN>`. Your gateway team owns the existing gateway, its certificate, listener, backend settings, DNS and WAF policy if used. Your Azure/network team owns any peering and extra Bridge network security group (NSG) rules. Neither route makes the Bridge private-only.

## Choose how the gateway will reach the Bridge

| Route | Use it when | Gateway backend target | Network work |
| --- | --- | --- | --- |
| [Public backend](#public-backend-use-the-bridge-fqdn) | Your gateway can reach the Bridge's public endpoint and your policy permits it. | `<BRIDGE_FQDN>` | No VNet peering. Optionally restrict direct HTTPS to the gateway's public IP. |
| [Peered private backend](#peered-private-backend-use-the-bridge-nic-ip) | You require the **gateway-to-Bridge** traffic to use private addresses and can manage peering and backend IP changes. | Bridge NIC private IP | Peer both VNets and allow traffic from the gateway subnet. |

Choose **one** backend route; do not perform the other route's gateway, peering or NSG steps. If your policy forbids a public IP on the Bridge at all, neither workaround meets it. A Terraform change and a different TLS/operations design would be needed.

## Prepare the Bridge for either route

1. Choose `<GATEWAY_HOSTNAME>`, the address Hurdle users will reach through your existing gateway (for example, `labs.example.org`). Arrange a valid gateway listener certificate and DNS for that name. Register `wss://<GATEWAY_HOSTNAME>` at the [Hurdle Lab Bridge registration page](https://manage.hurdle.live/lab/bridges/new) to obtain the Bridge secret **before** deploying the VM.
2. If you chose the peered private backend, check the [private route's network prerequisites](#peered-private-backend-use-the-bridge-nic-ip) **before applying Terraform**. The two VNet address ranges must not overlap. Set the module's VNet and subnet CIDRs to suitable values before deployment if its defaults conflict with your existing network.
3. Start from the [`infra-standard` example](../infra-standard/README.md) and its Terraform files. Its `main.tf` currently pins module version `1.3.0`; change that pin to `1.3.1` for the version described here. Put the issued secret in `bridge_lab_secret`, choose a separate `bridge_subdomain` for the Bridge's Azure DNS name, and leave `bridge_ingress_mode` at its `direct_pip` default (or set it explicitly in the module call):

   ```hcl
   bridge_ingress_mode = "direct_pip"
   ```

4. Deploy the infrastructure as described in the standard example. Then read its output:

   ```shell
   terraform output -raw bridge_public_fqdn
   ```

Call that output `<BRIDGE_FQDN>` (for example, `my-bridge.uksouth.cloudapp.azure.com`). The gateway presents its certificate for `<GATEWAY_HOSTNAME>` to users. The Bridge presents a **different** certificate for `<BRIDGE_FQDN>` to the gateway. Use `<BRIDGE_FQDN>` as the backend TLS hostname and probe host in either route, including when the backend target is a private IP. This keeps certificate name validation and SNI aligned with the Bridge certificate; see [Microsoft's end-to-end TLS guidance](https://learn.microsoft.com/en-us/azure/application-gateway/ssl-overview).

Do not select `appgw_waf`: that mode creates another Application Gateway, its public IP, subnet and WAF policy. The `bridge_appgw_*` inputs cannot point at an existing gateway. Do not import your shared gateway into this module's Terraform state; its gateway resource describes an entire gateway and would try to reconcile yours to that configuration.

## Public backend: use the Bridge FQDN

Use this route when the existing gateway has a public frontend and can reach the Bridge's public endpoint. **Do not perform the peering or private-IP lookup below.** The gateway routes to `<BRIDGE_FQDN>` over the public path, with HTTPS re-encryption to the Bridge.

```text
Azure resources (may span subscriptions)
├── Customer-managed resource group
│   └── Existing Application Gateway v2 (WAF if used)
│       ├── Public HTTPS listener: <GATEWAY_HOSTNAME>
│       └── Backend pool: <BRIDGE_FQDN>
│
└── Hurdle module-managed resource group
    ├── Bridge public IP and DNS name: <BRIDGE_FQDN>
    ├── Bridge NSG: nsg-hurdle-lab-bridge
    └── vnet-hurdle-lab
        └── snet-hurdle-lab-bridge
            └── Bridge VM (public IP attached; NSG on its NIC)

Client ── HTTPS/WSS ──> <GATEWAY_HOSTNAME> (customer gateway)
       ── HTTPS :443 over public path ──> <BRIDGE_FQDN> (Bridge public IP)
       ──> Bridge VM

VNet peering: none for this route.
```

The gateway team configures its existing Application Gateway v2:

| Gateway item | Public-backend setting |
| --- | --- |
| Backend pool | Add `<BRIDGE_FQDN>` as an FQDN target. |
| Backend setting | HTTPS on port 443; explicitly override the backend hostname to `<BRIDGE_FQDN>`. Keep backend certificate name and chain validation enabled. |
| Custom health probe | HTTPS on port 443, host `<BRIDGE_FQDN>`, path `/`, accepting HTTP status `200-399`; associate it with the backend setting. |
| Frontend and route | HTTPS listener with a certificate for `<GATEWAY_HOSTNAME>`; route it to this pool and setting. On a shared gateway, use a multi-site listener and a rule priority that does not conflict with existing sites. Redirect gateway HTTP to HTTPS if exposed. |
| DNS | Point `<GATEWAY_HOSTNAME>` to the gateway's public frontend. |

The Azure/network team may restrict direct Bridge HTTPS. In `direct_pip` mode the module's NSG allows inbound HTTP 80 from `*` at priority 110 and HTTPS 443 from `*` at priority 120. To make the gateway the only HTTPS caller, add customer-managed inbound rules **ahead of priority 120**: allow TCP 443 from the gateway frontend public IP, then deny TCP 443 from other sources. Use free priorities (for example 105 and 115), and verify the gateway's effective source address and NSG rules before enforcing the deny. Azure documents that a public backend sees the gateway frontend public IP; see [how Application Gateway routes requests](https://learn.microsoft.com/en-us/azure/application-gateway/how-application-gateway-works).

**Do not use this route** if policy forbids the gateway-to-Bridge leg traversing the public endpoint. Use the peered private backend below if its prerequisites can be met. A private backend does not remove the module-created Bridge public IP.

## Peered private backend: use the Bridge NIC IP

Use this route when the gateway-to-Bridge connection must stay on private addresses. **Do not put `<BRIDGE_FQDN>` in the backend pool** for this route: it resolves to the Bridge's public IP. Keep it as the backend TLS hostname and probe host instead. The existing gateway still needs a listener reachable by your Hurdle users; the diagram shows a public listener.

Before deploying the Bridge, the Azure/network team checks that the gateway VNet and lab VNet CIDRs do not overlap. After deployment, create a peering from the gateway VNet to `vnet-hurdle-lab` **and** a peering in the reverse direction. Confirm both show `Connected`, allow virtual network access, and check effective routes and any gateway-subnet controls permit TCP 443 to the Bridge subnet. Azure requires a network connection such as [VNet peering for a private-IP backend](https://learn.microsoft.com/en-us/azure/application-gateway/application-gateway-components); [peering requires non-overlapping ranges and a link in each direction](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-peering).

```text
Azure resources (may span subscriptions)
├── Customer-managed resource group
│   └── Customer gateway VNet
│       └── Application Gateway subnet
│           └── Existing Application Gateway v2 (WAF if used)
│               ├── HTTPS listener: <GATEWAY_HOSTNAME>
│               └── Backend pool: Bridge NIC private IP (dynamic)
│
└── Hurdle module-managed resource group
    ├── Bridge public IP: <BRIDGE_FQDN> (still attached for Bridge TLS)
    ├── Bridge NSG: nsg-hurdle-lab-bridge
    └── vnet-hurdle-lab
        └── snet-hurdle-lab-bridge
            └── Bridge VM / NIC private IP (dynamic)

Customer gateway VNet <── bidirectional VNet peering ──> vnet-hurdle-lab
Client ── HTTPS/WSS ──> <GATEWAY_HOSTNAME> (customer gateway)
       ── HTTPS :443 through peering ──> Bridge NIC private IP

Backend TLS hostname/SNI: <BRIDGE_FQDN>, not the private IP.
Bridge public IP remains attached; this is not a private-only Bridge.
```

Read the deployed Bridge VM name and resource group from the infrastructure example's outputs. Use Azure CLI to find its NIC ID, then its current private IP:

```shell
terraform output -raw resource_group_name
terraform output -raw bridge_vm_name
az vm show --resource-group "<RESOURCE_GROUP>" --name "<BRIDGE_VM_NAME>" --query "networkProfile.networkInterfaces[0].id" -o tsv
az network nic show --ids "<NIC_ID_FROM_PREVIOUS_COMMAND>" --query "ipConfigurations[0].privateIPAddress" -o tsv
```

The gateway team configures its existing Application Gateway v2:

| Gateway item | Peered-private-backend setting |
| --- | --- |
| Backend pool | Add the **current Bridge NIC private IP** as an IP target. |
| Backend setting | HTTPS on port 443; explicitly override the backend hostname to `<BRIDGE_FQDN>`. Do not pick the hostname from the IP target. Keep backend certificate name and chain validation enabled. |
| Custom health probe | HTTPS on port 443, host `<BRIDGE_FQDN>`, path `/`, accepting HTTP status `200-399`; associate it with the backend setting. |
| Frontend and route | HTTPS listener with a certificate for `<GATEWAY_HOSTNAME>`; route it to this pool and setting. On a shared gateway, use a multi-site listener and a non-conflicting rule priority. Redirect gateway HTTP to HTTPS if exposed. |
| DNS | Point `<GATEWAY_HOSTNAME>` to the gateway frontend that your users can reach. |

For a private-IP backend, the Bridge sees traffic from the gateway's **instance private IPs**, not its frontend public IP. The Azure/network team should add customer-managed Bridge NSG inbound rules ahead of the module's broad priority-120 HTTPS rule: allow TCP 443 from the gateway subnet CIDR, then deny other TCP 443 sources. Use free priorities (for example 105 and 115) and verify effective rules and backend health before enforcing the deny. The module assigns the Bridge NIC's private IP dynamically; after a NIC/VM replacement, look it up again and update the gateway pool. See [Application Gateway routing behavior](https://learn.microsoft.com/en-us/azure/application-gateway/how-application-gateway-works).

The Bridge **still has a public IP** in this route. The `direct_pip` configuration uses `<BRIDGE_FQDN>` for its own TLS certificate. Keep port 80 reachable until certificate issuance and renewal have been verified in your deployment. Do not remove the public IP or treat this as a private-only design.

**Do not use this route** if the VNets cannot be connected, their address ranges overlap and cannot be changed, or your team cannot maintain the dynamic backend IP. The public route above is simpler if policy permits public backend traffic; neither route works when policy forbids any Bridge public IP.

## Validate the route you chose

1. Confirm the gateway reports the Bridge backend as healthy. For TLS or probe failures, compare the backend setting, probe host and Bridge certificate name. A private backend also needs its peering, routes and NSG checked; a public backend needs public reachability.
2. Open `https://<GATEWAY_HOSTNAME>/` and confirm the Bridge holding page loads without a certificate warning or redirect to `<BRIDGE_FQDN>`.
3. Start a fresh Hurdle lab session and join from the web or desktop app. Confirm the WebSocket stays connected through the gateway. Application Gateway [supports WebSockets](https://learn.microsoft.com/en-us/azure/application-gateway/application-gateway-websocket); check that the backend request timeout accommodates the connection.
4. Confirm direct `https://<BRIDGE_FQDN>/` access follows the NSG policy you chose. Check Bridge certificate issuance and renewal before reducing port-80 access.
5. Run `terraform plan` after customer-managed NSG changes and module upgrades. Review gateway health after any Bridge replacement or DNS change; for the private route, recheck the NIC private IP and update the backend pool when it changes.

These are customer-managed integration paths, not a Terraform BYO App Gateway feature. Validate the selected route in your Azure environment before using it for live sessions.
