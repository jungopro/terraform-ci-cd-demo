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

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${terraform.workspace}-aks"
  location            = var.create_resource_group ? azurerm_resource_group.rg[0].location : var.resource_group_location
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  dns_prefix          = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  kubernetes_version  = var.k8s_version

  network_profile {
    network_plugin = "azure"
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  role_based_access_control {
    enabled = true
  }

  dynamic "agent_pool_profile" {
    for_each = var.profiles
    iterator = profile
    content {
      name            = lookup(profile.value, "name")
      count           = lookup(profile.value, "count")
      vm_size         = lookup(profile.value, "vm_size")
      os_type         = lookup(profile.value, "os_type")
      os_disk_size_gb = lookup(profile.value, "os_disk_size_gb")
      max_pods        = lookup(profile.value, "max_pods")
      vnet_subnet_id  = azurerm_subnet.subnet["subnet-1"].id
      type            = "VirtualMachineScaleSets"
    }
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${terraform.workspace}-pip"
  location            = var.create_resource_group ? azurerm_resource_group.rg[0].location : var.resource_group_location
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  allocation_method   = "Static"
  tags                = local.tags
}
