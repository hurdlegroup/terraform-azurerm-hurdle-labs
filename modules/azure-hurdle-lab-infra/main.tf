locals {
  is_direct_pip_ingress_mode = var.bridge_ingress_mode == "direct_pip"
  is_appgw_ingress_mode      = var.bridge_ingress_mode == "appgw_waf"

  bridge_public_fqdn = local.is_appgw_ingress_mode ? azurerm_public_ip.bridge_appgw[0].fqdn : azurerm_public_ip.bridge.fqdn

  # If Lab Bridge ingress is NAT Gateway, then Bridge VM handles TLS.
  # If Lab Bridge ingress is Application Gateway, then App Gateway handles TLS, and Bridge VM receives unencrypted traffic.
  guacws_server_settings_raw = {
    TlsMode   = local.is_appgw_ingress_mode ? "offloaded" : "letsencrypt"
    HttpPort  = 80
    HttpsPort = local.is_direct_pip_ingress_mode ? 443 : null
    LetsEncrypt = local.is_direct_pip_ingress_mode ? {
      Domains      = [local.bridge_public_fqdn]
      EmailAddress = var.bridge_technical_contact_email
    } : null
  }

  guacws_server_settings = {
    for key, value in local.guacws_server_settings_raw : key => value if value != null
  }

  guacws_appsettings = jsonencode({
    Server = local.guacws_server_settings
    Cipher = {
      Key = var.bridge_lab_secret
    }
  })

  generated_bridge_cloud_init = <<-EOT
#cloud-config
${yamlencode({
  write_files = [
    {
      path        = "/etc/guacws/appsettings.Production.json"
      owner       = "root:root"
      permissions = "0644"
      content     = local.guacws_appsettings
    }
  ]
  runcmd = [
    "mkdir -p /etc/guacws",
    "chown guacd:guacd /etc/guacws/appsettings.Production.json",
    "supervisorctl restart guacws"
  ]
})}
EOT

rendered_cloud_init = var.bridge_cloud_init != null ? var.bridge_cloud_init : (
  var.bridge_cloud_init_template != null ? templatefile(var.bridge_cloud_init_template, {}) : local.generated_bridge_cloud_init
)

is_nat_mode              = var.machines_egress_mode == "nat"
is_managed_firewall_mode = var.machines_egress_mode == "firewall_module_provisioned"
is_byo_firewall_mode     = var.machines_egress_mode == "firewall_customer_existing"
use_byo_route_table      = local.is_byo_firewall_mode && var.machines_byo_route_table_name != null
}

resource "random_id" "suffix" {
  byte_length = 2
}

resource "azurerm_resource_group" "hurdle_lab" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hurdle_lab" {
  name                = var.vnet_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "bridge" {
  name                 = var.bridge_subnet_name
  resource_group_name  = azurerm_resource_group.hurdle_lab.name
  virtual_network_name = azurerm_virtual_network.hurdle_lab.name
  address_prefixes     = [var.bridge_subnet_cidr]
}

resource "azurerm_subnet" "machines" {
  name                 = var.machines_subnet_name
  resource_group_name  = azurerm_resource_group.hurdle_lab.name
  virtual_network_name = azurerm_virtual_network.hurdle_lab.name
  address_prefixes     = [var.machines_subnet_cidr]
}

resource "azurerm_public_ip" "machines_nat" {
  count               = local.is_nat_mode ? 1 : 0
  name                = "pip-${var.machines_nat_name}"
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "machines" {
  count               = local.is_nat_mode ? 1 : 0
  name                = var.machines_nat_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  sku_name            = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "machines" {
  count                = local.is_nat_mode ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.machines[0].id
  public_ip_address_id = azurerm_public_ip.machines_nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "machines" {
  count          = local.is_nat_mode ? 1 : 0
  subnet_id      = azurerm_subnet.machines.id
  nat_gateway_id = azurerm_nat_gateway.machines[0].id
}

resource "azurerm_subnet" "firewall" {
  count                = local.is_managed_firewall_mode ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hurdle_lab.name
  virtual_network_name = azurerm_virtual_network.hurdle_lab.name
  address_prefixes     = [var.machines_managed_firewall_subnet_cidr]
}

resource "azurerm_public_ip" "managed_firewall" {
  count               = local.is_managed_firewall_mode ? 1 : 0
  name                = var.machines_managed_firewall_pip_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "managed" {
  count               = local.is_managed_firewall_mode ? 1 : 0
  name                = var.machines_managed_firewall_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall[0].id
    public_ip_address_id = azurerm_public_ip.managed_firewall[0].id
  }
}

resource "azurerm_firewall_network_rule_collection" "machines_baseline" {
  count               = local.is_managed_firewall_mode ? 1 : 0
  name                = "machines-baseline-network"
  azure_firewall_name = azurerm_firewall.managed[0].name
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "allow-dns"
    protocols             = ["TCP", "UDP"]
    source_addresses      = [var.machines_subnet_cidr]
    destination_ports     = ["53"]
    destination_addresses = ["*"]
  }

  rule {
    name                  = "allow-ntp"
    protocols             = ["UDP"]
    source_addresses      = [var.machines_subnet_cidr]
    destination_ports     = ["123"]
    destination_addresses = ["*"]
  }

  rule {
    name                  = "allow-icmp"
    protocols             = ["ICMP"]
    source_addresses      = [var.machines_subnet_cidr]
    destination_ports     = ["*"]
    destination_addresses = ["*"]
  }
}

resource "azurerm_firewall_application_rule_collection" "machines_web" {
  count               = local.is_managed_firewall_mode ? 1 : 0
  name                = "machines-web-browsing"
  azure_firewall_name = azurerm_firewall.managed[0].name
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  priority            = 110
  action              = "Allow"

  rule {
    name             = "allow-http-https"
    source_addresses = [var.machines_subnet_cidr]
    target_fqdns     = ["*"]

    protocol {
      type = "Http"
      port = 80
    }

    protocol {
      type = "Https"
      port = 443
    }
  }
}

data "azurerm_route_table" "byo" {
  count               = local.use_byo_route_table ? 1 : 0
  name                = var.machines_byo_route_table_name
  resource_group_name = coalesce(var.machines_byo_route_table_resource_group_name, azurerm_resource_group.hurdle_lab.name)
}

resource "azurerm_route_table" "machines_egress" {
  count               = (!local.is_nat_mode && !local.use_byo_route_table) ? 1 : 0
  name                = var.machines_route_table_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  tags                = var.tags
}

resource "azurerm_route" "machines_default_egress" {
  count                  = local.is_nat_mode ? 0 : 1
  name                   = "default-egress-via-firewall"
  resource_group_name    = local.use_byo_route_table ? data.azurerm_route_table.byo[0].resource_group_name : azurerm_resource_group.hurdle_lab.name
  route_table_name       = local.use_byo_route_table ? data.azurerm_route_table.byo[0].name : azurerm_route_table.machines_egress[0].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.is_managed_firewall_mode ? azurerm_firewall.managed[0].ip_configuration[0].private_ip_address : var.machines_byo_firewall_private_ip
}

resource "azurerm_subnet_route_table_association" "machines" {
  count          = local.is_nat_mode ? 0 : 1
  subnet_id      = azurerm_subnet.machines.id
  route_table_id = local.use_byo_route_table ? data.azurerm_route_table.byo[0].id : azurerm_route_table.machines_egress[0].id
}

resource "azurerm_subnet" "bridge_edge" {
  count                = local.is_appgw_ingress_mode ? 1 : 0
  name                 = var.bridge_edge_subnet_name
  resource_group_name  = azurerm_resource_group.hurdle_lab.name
  virtual_network_name = azurerm_virtual_network.hurdle_lab.name
  address_prefixes     = [var.bridge_edge_subnet_cidr]
}

resource "azurerm_public_ip" "bridge_appgw" {
  count               = local.is_appgw_ingress_mode ? 1 : 0
  name                = var.bridge_appgw_pip_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.bridge_subdomain
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "bridge" {
  count               = local.is_appgw_ingress_mode ? 1 : 0
  name                = var.bridge_appgw_waf_policy_name
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  location            = azurerm_resource_group.hurdle_lab.location
  tags                = var.tags

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "bridge" {
  count               = local.is_appgw_ingress_mode ? 1 : 0
  name                = var.bridge_appgw_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  firewall_policy_id  = azurerm_web_application_firewall_policy.bridge[0].id
  tags                = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.bridge_appgw_key_vault_uami_id]
  }

  sku {
    name     = var.bridge_appgw_sku_name
    tier     = var.bridge_appgw_sku_tier
    capacity = var.bridge_appgw_capacity
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.bridge_edge[0].id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.bridge_appgw[0].id
  }

  ssl_certificate {
    name                = "bridge-cert"
    key_vault_secret_id = var.bridge_appgw_tls_key_vault_secret_id
  }

  backend_address_pool {
    name         = "bridge-backend"
    ip_addresses = [azurerm_network_interface.bridge.private_ip_address]
  }

  backend_http_settings {
    name                                = "bridge-http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 30
    probe_name                          = "bridge-probe"
    pick_host_name_from_backend_address = false
  }

  probe {
    name                                      = "bridge-probe"
    protocol                                  = "Http"
    host                                      = "127.0.0.1"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false
    minimum_servers                           = 0
    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "bridge-cert"
  }

  redirect_configuration {
    name                 = "http-to-https"
    redirect_type        = "Permanent"
    target_listener_name = "https-listener"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                        = "http-redirect"
    rule_type                   = "Basic"
    http_listener_name          = "http-listener"
    redirect_configuration_name = "http-to-https"
    priority                    = 100
  }

  request_routing_rule {
    name                       = "https-bridge"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "bridge-backend"
    backend_http_settings_name = "bridge-http-settings"
    priority                   = 110
  }
}

resource "azurerm_public_ip" "bridge" {
  name                = var.bridge_pip_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.is_direct_pip_ingress_mode ? var.bridge_subdomain : null
  tags                = var.tags
}

resource "azurerm_network_security_group" "bridge" {
  name                = var.bridge_nsg_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "bridge_ssh" {
  name                        = "allow-ssh-from-vpn"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.bridge_ssh_allowed_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.hurdle_lab.name
  network_security_group_name = azurerm_network_security_group.bridge.name
}

resource "azurerm_network_security_rule" "bridge_http" {
  name                        = "allow-http"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = local.is_appgw_ingress_mode ? var.bridge_edge_subnet_cidr : "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.hurdle_lab.name
  network_security_group_name = azurerm_network_security_group.bridge.name
}

resource "azurerm_network_security_rule" "bridge_https" {
  count                       = local.is_direct_pip_ingress_mode ? 1 : 0
  name                        = "allow-https"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.hurdle_lab.name
  network_security_group_name = azurerm_network_security_group.bridge.name
}

resource "azurerm_network_interface" "bridge" {
  name                = "nic-${var.bridge_vm_name}"
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.bridge.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bridge.id
  }
}

resource "azurerm_network_interface_security_group_association" "bridge" {
  network_interface_id      = azurerm_network_interface.bridge.id
  network_security_group_id = azurerm_network_security_group.bridge.id
}

resource "azurerm_linux_virtual_machine" "bridge" {
  name                = var.bridge_vm_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  size                = var.bridge_vm_size
  admin_username      = var.bridge_admin_username
  network_interface_ids = [
    azurerm_network_interface.bridge.id
  ]
  disable_password_authentication = true
  tags                            = var.tags

  admin_ssh_key {
    username   = var.bridge_admin_username
    public_key = var.bridge_ssh_public_key
  }

  source_image_id = var.bridge_source_image_id

  os_disk {
    name                 = "osdisk-${var.bridge_vm_name}-${random_id.suffix.hex}"
    caching              = "ReadWrite"
    storage_account_type = var.bridge_os_disk_storage_account_type
    disk_size_gb         = var.bridge_os_disk_size_gb
  }

  custom_data = local.rendered_cloud_init != null ? base64encode(local.rendered_cloud_init) : null
}
