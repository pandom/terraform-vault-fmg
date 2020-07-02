# Azure Linux Virtual Machine
resource azurerm_resource_group "kv_reader" {
  name     = "kv_reader"
  location = var.location
}

resource azurerm_virtual_network "this" {
  name                = var.deployment_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.kv_reader.location
  resource_group_name = azurerm_resource_group.kv_reader.name
}

resource azurerm_subnet "this" {
  name                 = var.deployment_name
  resource_group_name  = azurerm_resource_group.kv_reader.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource azurerm_network_interface "this" {
  count               = var.cluster_size
  name                = "${var.deployment_name}-${count.index}-nic"
  location            = azurerm_resource_group.kv_reader.location
  resource_group_name = azurerm_resource_group.kv_reader.name

  ip_configuration {
    name                          = var.deployment_name
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.machines[count.index].id
  }
}

data azurerm_image "this" {
  name_regex          = "^vault-client-1.4.0"
  resource_group_name = "gopacker"
  sort_descending = true
}

data template_file "userdata" {
  count = var.cluster_size
  template = file("${path.module}/templates/userdata.yaml")

  vars = {
    vault_conf     = base64encode(templatefile("${path.module}/templates/vault.conf",
      {
        vault_addr = var.vault_url
        vault_role = "kv_reader"
        template_command = "sudo systemctl restart nginx"
        ca_file_location = "/etc/vault.d/ca.cer"
        cert_file_location = "/etc/vault.d/nginx.cer"
        key_file_location = "/etc/vault.d/nginx.key"
        common_name = "vault-client-0"
      }
    )),
    nginx = base64encode(file("${path.module}/templates/nginx"))
  }
}

resource azurerm_linux_virtual_machine "this" {
  count               = var.cluster_size
  name                = "${var.deployment_name}-${count.index}"
  resource_group_name = azurerm_resource_group.kv_reader.name
  location            = azurerm_resource_group.kv_reader.location
  size                = var.server_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.this[count.index].id,
  ]
  custom_data = base64encode(data.template_file.userdata[count.index].rendered)

  tags = {
    application = "nginx"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username = "grant"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_id = data.azurerm_image.this.id

  identity {
    type = "SystemAssigned"
  }
}

resource azurerm_public_ip "this" {
  name                = var.deployment_name
  location            = var.location
  resource_group_name = azurerm_resource_group.kv_reader.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource azurerm_public_ip "machines" {
  count               = var.cluster_size
  name                = "${var.deployment_name}-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.kv_reader.name
  sku                 = "Standard"
  allocation_method   = "Static"
}


resource azurerm_lb "this" {
  name                = var.deployment_name
  location            = var.location
  resource_group_name = azurerm_resource_group.kv_reader.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.deployment_name
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

resource azurerm_lb_rule "this" {
  resource_group_name            = azurerm_resource_group.kv_reader.name
  loadbalancer_id                = azurerm_lb.this.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = var.deployment_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
}

resource azurerm_lb_backend_address_pool "this" {
  resource_group_name = azurerm_resource_group.kv_reader.name
  loadbalancer_id     = azurerm_lb.this.id
  name                = var.deployment_name
}

resource azurerm_network_interface_backend_address_pool_association "this" {
  count                   = var.cluster_size
  network_interface_id    = azurerm_network_interface.this[count.index].id
  ip_configuration_name   = var.deployment_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
}

resource azurerm_network_security_group "this" {
  name                = var.deployment_name
  location            = azurerm_resource_group.kv_reader.location
  resource_group_name = azurerm_resource_group.kv_reader.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" #formatlist("%s/32", local.permitted_ips)
    destination_address_prefixes = azurerm_linux_virtual_machine.this.*.private_ip_address
  }

  security_rule {
    name                       = "https"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefixes = azurerm_linux_virtual_machine.this.*.private_ip_address
  }
}

resource azurerm_network_interface_security_group_association "this" {
  count = var.cluster_size
  network_interface_id      = azurerm_network_interface.this[count.index].id
  network_security_group_id = azurerm_network_security_group.this.id
}

/*
resource vault_pki_secret_backend_cert "this" {
  backend     = vault_mount.pki.path
  name        = vault_pki_secret_backend_role.nginx.name
  common_name = "vault-client-0"
  alt_names   = ["nginx.azure-vault.go.hashidemos.io"]
  ip_sans     = azurerm_public_ip.machines.*.ip_address
  auto_renew  = true
  ttl = "5m"
}
*/

data aws_route53_zone "this" {
  name         = "go.hashidemos.io"
  private_zone = false
}

resource aws_route53_record "this" {
  zone_id = data.aws_route53_zone.this.id
  name    = "nginx.azure-vault.${data.aws_route53_zone.this.name}"
  type    = "A"
  ttl     = "300"
  records = [azurerm_public_ip.this.ip_address]
}