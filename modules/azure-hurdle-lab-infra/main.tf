locals {
  bridge_slug = substr(lower(var.bridge_subdomain_slug), 0, 40)
  dns_label   = "${trim(local.bridge_slug, "-")}-hurdle-bridge"

  guacws_appsettings = jsonencode({
    Server = {
      HttpPort  = 80
      HttpsPort = 443
      LetsEncrypt = {
        Domains      = [azurerm_public_ip.bridge.fqdn]
        EmailAddress = var.bridge_technical_contact_email
      }
    }
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
  name                = "pip-${var.machines_nat_name}"
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "machines" {
  name                = var.machines_nat_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  sku_name            = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "machines" {
  nat_gateway_id       = azurerm_nat_gateway.machines.id
  public_ip_address_id = azurerm_public_ip.machines_nat.id
}

resource "azurerm_subnet_nat_gateway_association" "machines" {
  subnet_id      = azurerm_subnet.machines.id
  nat_gateway_id = azurerm_nat_gateway.machines.id
}

resource "azurerm_public_ip" "bridge" {
  name                = var.bridge_pip_name
  location            = azurerm_resource_group.hurdle_lab.location
  resource_group_name = azurerm_resource_group.hurdle_lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.dns_label
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
    storage_account_type = "Standard_LRS"
  }

  custom_data = local.rendered_cloud_init != null ? base64encode(local.rendered_cloud_init) : null
}
