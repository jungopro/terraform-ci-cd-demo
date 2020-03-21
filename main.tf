locals {
  tags = merge(var.tags, { "workspace" = "${terraform.workspace}" }) # add terraform workspace tag to any additional tags given as input
}

#######################
### Azure Resources ###
#######################

### Resource Group

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0 # conditional creation
  name     = "${terraform.workspace}-${var.resource_group_name}"
  location = var.resource_group_location

  tags = local.tags
}

module "vnet" {
  source                  = "jungopro/vnet/azurerm"
  version                 = "1.401.0"
  tags                    = local.tags
  resource_group_name     = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  resource_group_location = var.create_resource_group ? azurerm_resource_group.rg[0].location : var.resource_group_location
  vnet_name               = "${terraform.workspace}-${var.vnet_name}"
  vnet_cidr               = var.vnet_cidr
  vnet_dns_servers        = var.vnet_dns_servers
  subnets                 = var.subnets
}
### AKS Cluster

resource "azurerm_kubernetes_cluster" "aks" {
  name                       = "${terraform.workspace}-aks"
  location                   = var.create_resource_group ? azurerm_resource_group.rg[0].location : var.resource_group_location
  resource_group_name        = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  dns_prefix                 = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  kubernetes_version         = var.k8s_version
  tags                       = local.tags
  enable_pod_security_policy = var.enable_pod_security_policy

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  role_based_access_control {
    enabled = true
  }

  default_node_pool {
    name            = "default"
    node_count      = var.default_pool_node_count
    vm_size         = "Standard_B2ms"
    os_disk_size_gb = 30
    max_pods        = 30
    vnet_subnet_id  = lookup(module.vnet.subnets_full_info, element(keys(var.subnets), 0)).id
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }
  }

  windows_profile {
    admin_username = var.admin_username
    admin_password = var.windows_node_admin_password
  }

  linux_profile {
    admin_username = var.admin_username
    ssh_key {
      key_data = file(var.public_ssh_key_path)
    }
  }
}

### Additional AKS Node Pools

resource "azurerm_kubernetes_cluster_node_pool" "pools" {
  for_each              = var.node_pools
  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = lookup(each.value, "vm_size")
  node_count            = lookup(each.value, "node_count")
  os_type               = lookup(each.value, "os_type")
}

### DNS

data "azurerm_dns_zone" "dns_zone" {
  name                = var.zone_name
  resource_group_name = "devops"
}

resource "azurerm_dns_cname_record" "app" {
  name                = "phippyandfriends.${terraform.workspace}"
  zone_name           = data.azurerm_dns_zone.dns_zone.name
  resource_group_name = "devops"
  ttl                 = 300
  record              = "parrot.${azurerm_kubernetes_cluster.aks.addon_profile.0.http_application_routing[0].http_application_routing_zone_name}"
}

#######################
#### K8s Resources ####
#######################

### Application Namespace

resource "kubernetes_namespace" "phippyandfriends" {
  metadata {
    name = "phippyandfriends"
  }
}

### Application CRB

resource "kubernetes_cluster_role_binding" "default_view" {
  metadata {
    name = "default-view"
  }
  role_ref {
    kind      = "ClusterRole"
    name      = "view"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = kubernetes_namespace.phippyandfriends.metadata.0.name
    api_group = ""
  }
}

######################
### Helm Resources ###
######################

### Define Parrot additional values to be passed as inputs to the chart

locals {
  parrot_values = {
    "ingress.basedomain" = azurerm_kubernetes_cluster.aks.addon_profile.0.http_application_routing[0].http_application_routing_zone_name
    "ingress.alias"      = "phippyandfriends.${terraform.workspace}.${var.zone_name}"
  }
}

### Create helm releases for each app in var.apps

resource "helm_release" "phippyandfriends" {
  for_each            = var.apps
  name                = each.key
  repository          = "https://${var.repo_name}.azurecr.io/helm/v1/repo"
  repository_username = var.repo_username
  repository_password = var.repo_password
  chart               = each.key
  namespace           = kubernetes_namespace.phippyandfriends.metadata.0.name
  version             = lookup(each.value, "version") != "" ? lookup(each.value, "version") : null

  set {
    name  = "image.repository"
    value = "${var.repo_name}.azurecr.io/${each.key}"
  }

  dynamic "set" {
    for_each = local.parrot_values
    content {
      name  = each.key == "parrot" ? set.key : ""
      value = each.key == "parrot" ? set.value : ""
    }
  }

  depends_on = [
    kubernetes_cluster_role_binding.default_view
  ]
}