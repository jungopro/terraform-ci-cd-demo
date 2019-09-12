locals {
  tags = merge(var.tags, { "workspace" = "${terraform.workspace}" })
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = "${terraform.workspace}-${var.resource_group_name}"
  location = var.resource_group_location

  tags = merge({ "Name" = format("%s", var.resource_group_name) }, local.tags)
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${terraform.workspace}-${var.vnet_name}"
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  address_space       = var.vnet_cidr
  location            = var.create_resource_group ? azurerm_resource_group.rg[0].location : var.resource_group_location
  dns_servers         = var.vnet_dns_servers
  tags                = merge({ "Name" = format("%s", var.vnet_name) }, local.tags)
}

resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = lookup(each.value, "name")
  resource_group_name  = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = lookup(each.value, "cidr")
  service_endpoints    = lookup(each.value, "service_endpoints")
}

resource "random_integer" "uuid" { 
  min = 100
  max = 999
}

resource "azurerm_public_ip" "ingress_ip" {
  name                = "${azurerm_resource_group.rg.name}${random_integer.uuid.result}pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  domain_name_label = "${azurerm_resource_group.rg.name}${random_integer.uuid.result}"

  tags = {
    environment = "${terraform.workspace}"
  }
}