# Deploy Hurdle Labs Infrastructure in Azure

Deploys the Azure resource group, networking, bridge VM, bridge ingress, and lab-machine egress for Hurdle Labs.

Use this submodule directly when an Azure infrastructure operator deploys the lab separately from the Entra/RBAC administrator. It owns the infrastructure state and exposes `resource_group_id` for the identity-module hand-off.

For usage examples usage instructions see:
- [`examples/infra-standard`](../../examples/infra-standard)
- [`examples/infra-advanced-egress`](../../examples/infra-advanced-egress)
- [`examples/infra-advanced-ingress`](../../examples/infra-advanced-ingress)
