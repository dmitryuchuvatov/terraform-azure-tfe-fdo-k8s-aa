# Resource Group
resource "azurerm_resource_group" "tfe" {
  name     = "${var.environment_name}-resources"
  location = var.region
}

# VNet
resource "azurerm_virtual_network" "tfe" {
  name                = "${var.environment_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.tfe.location
  resource_group_name = azurerm_resource_group.tfe.name
}

# Subnets
resource "azurerm_subnet" "public1" {
  name                 = "${var.environment_name}-public1"
  resource_group_name  = azurerm_resource_group.tfe.name
  virtual_network_name = azurerm_virtual_network.tfe.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 1)]
}

resource "azurerm_subnet" "private1" {
  name                 = "${var.environment_name}-private1"
  resource_group_name  = azurerm_resource_group.tfe.name
  virtual_network_name = azurerm_virtual_network.tfe.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 11)]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "private2" {
  name                 = "${var.environment_name}-private2"
  resource_group_name  = azurerm_resource_group.tfe.name
  virtual_network_name = azurerm_virtual_network.tfe.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 12)]
}

# NSG and traffic rules
resource "azurerm_network_security_group" "tfe" {
  name                = "${var.environment_name}-nsg"
  location            = azurerm_resource_group.tfe.location
  resource_group_name = azurerm_resource_group.tfe.name
}

resource "azurerm_network_security_rule" "https" {
  name                        = "HTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.tfe.name
  network_security_group_name = azurerm_network_security_group.tfe.name
}

resource "azurerm_network_security_rule" "http" {
  name                        = "HTTP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.tfe.name
  network_security_group_name = azurerm_network_security_group.tfe.name
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "SSH"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.tfe.name
  network_security_group_name = azurerm_network_security_group.tfe.name
}

resource "azurerm_network_security_rule" "postgres" {
  name                        = "PostgreSQL"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = var.vnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.tfe.name
  network_security_group_name = azurerm_network_security_group.tfe.name
}

resource "azurerm_network_security_rule" "redis" {
  name                        = "Redis"
  priority                    = 140
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6379"
  source_address_prefix       = var.vnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.tfe.name
  network_security_group_name = azurerm_network_security_group.tfe.name
}

resource "azurerm_subnet_network_security_group_association" "tfe-public1" {
  subnet_id                 = azurerm_subnet.public1.id
  network_security_group_id = azurerm_network_security_group.tfe.id
}

resource "azurerm_subnet_network_security_group_association" "tfe-private1" {
  subnet_id                 = azurerm_subnet.private1.id
  network_security_group_id = azurerm_network_security_group.tfe.id
}

resource "azurerm_subnet_network_security_group_association" "tfe-private2" {
  subnet_id                 = azurerm_subnet.private2.id
  network_security_group_id = azurerm_network_security_group.tfe.id
}

# NAT and Public IP
resource "azurerm_nat_gateway" "tfe" {
  name                    = "${var.environment_name}-NAT-Gateway"
  location                = azurerm_resource_group.tfe.location
  resource_group_name     = azurerm_resource_group.tfe.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
}

resource "azurerm_public_ip" "tfe" {
  name                = "${var.environment_name}-NAT-PublicIP"
  location            = azurerm_resource_group.tfe.location
  resource_group_name = azurerm_resource_group.tfe.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

resource "azurerm_nat_gateway_public_ip_association" "tfe" {
  nat_gateway_id       = azurerm_nat_gateway.tfe.id
  public_ip_address_id = azurerm_public_ip.tfe.id
}

resource "azurerm_subnet_nat_gateway_association" "tfe_private1" {
  subnet_id      = azurerm_subnet.private1.id
  nat_gateway_id = azurerm_nat_gateway.tfe.id
}


# Database
resource "azurerm_private_dns_zone" "tfe" {
  name                = "${var.environment_name}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.tfe.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "tfe" {
  name                  = var.environment_name
  private_dns_zone_name = azurerm_private_dns_zone.tfe.name
  virtual_network_id    = azurerm_virtual_network.tfe.id
  resource_group_name   = azurerm_resource_group.tfe.name
}

resource "azurerm_postgresql_flexible_server" "tfe" {
  name                   = "${var.environment_name}-postgres"
  resource_group_name    = azurerm_resource_group.tfe.name
  location               = azurerm_resource_group.tfe.location
  version                = "14"
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  delegated_subnet_id    = azurerm_subnet.private1.id
  private_dns_zone_id    = azurerm_private_dns_zone.tfe.id
  administrator_login    = var.postgresql_user
  administrator_password = var.postgresql_password
  zone                   = "1"

  depends_on = [azurerm_private_dns_zone_virtual_network_link.tfe]
}

resource "azurerm_postgresql_flexible_server_database" "tfe" {
  name      = "tfe"
  server_id = azurerm_postgresql_flexible_server.tfe.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# To address a known issue - https://support.hashicorp.com/hc/en-us/articles/4548903433235-Terraform-Enterprise-External-Services-mode-with-Azure-Database-for-PostgreSQL-Flexible-Server-Failed-to-Initialize-**Plugins
resource "azurerm_postgresql_flexible_server_configuration" "tfe" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.tfe.id
  value     = "CITEXT,HSTORE,UUID-OSSP"
}

# Blob storage
resource "azurerm_storage_account" "tfe" {
  name                     = var.storage_name
  resource_group_name      = azurerm_resource_group.tfe.name
  location                 = azurerm_resource_group.tfe.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  routing {
    publish_microsoft_endpoints = true
    choice                      = "MicrosoftRouting"
  }
}

resource "azurerm_storage_container" "tfe" {
  name                  = "${var.environment_name}-container"
  storage_account_name  = azurerm_storage_account.tfe.name
  container_access_type = "private"
}

# Redis cache
resource "azurerm_redis_cache" "tfe" {
  name                      = "${var.environment_name}-redis"
  resource_group_name       = azurerm_resource_group.tfe.name
  location                  = azurerm_resource_group.tfe.location
  capacity                  = "1"
  family                    = "P"
  sku_name                  = "Premium"
  enable_non_ssl_port       = true
  private_static_ip_address = cidrhost(cidrsubnet(var.vnet_cidr, 8, 12), 22)
  subnet_id                 = azurerm_subnet.private2.id
  redis_version             = 6

  redis_configuration {
    maxmemory_reserved = "642"
    maxmemory_delta    = "642"
    maxmemory_policy   = "allkeys-lru"
  }
}

# AKS cluster
resource "azurerm_kubernetes_cluster" "tfe" {
  name                = var.environment_name
  resource_group_name = azurerm_resource_group.tfe.name
  location            = azurerm_resource_group.tfe.location
  dns_prefix          = var.environment_name

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D4s_v3"
    os_disk_size_gb = 50
    vnet_subnet_id  = azurerm_subnet.public1.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "TFE FDO AKS"
  }
}