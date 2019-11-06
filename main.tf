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

  /*agent_pool_profile {
    name            = "default"
    count           = 1
    vm_size         = "Standard_B2ms"
    os_type         = "Linux"
    os_disk_size_gb = 30
    max_pods        = 30
    vnet_subnet_id  = azurerm_subnet.subnet["subnet-1"].id
    type            = "VirtualMachineScaleSets"
  }*/

  dynamic "agent_pool_profile" {
    for_each = var.profiles
    content {
      name            = lookup(agent_pool_profile.value, "name")
      count           = 1
      vm_size         = "Standard_B2ms"
      os_type         = "Linux"
      os_disk_size_gb = 30
      max_pods        = 30
      vnet_subnet_id  = azurerm_subnet.subnet["subnet-1"].id
      type            = "VirtualMachineScaleSets"
    }
  }
}

variable "profiles" {
  type = map(object({
    name              = string
  }))
  default = {}
}
