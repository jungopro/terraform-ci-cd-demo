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

### vNet

resource "azurerm_virtual_network" "vnet" {
  name                = "${terraform.workspace}-${var.vnet_name}"
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  address_space       = var.vnet_cidr
  location            = var.create_resource_group ? azurerm_resource_group.rg[0].location : var.resource_group_location
  dns_servers         = var.vnet_dns_servers
  tags                = local.tags
}

### 1 or more subnets

resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = lookup(each.value, "cidr")
  service_endpoints    = lookup(each.value, "service_endpoints")
}

### AKS Cluster

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${terraform.workspace}-aks"
  location            = var.create_resource_group ? azurerm_resource_group.rg[0].location : var.resource_group_location
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  dns_prefix          = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  kubernetes_version  = var.k8s_version
  tags                = local.tags

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

  default_node_pool {
    name            = "default"
    node_count      = var.default_pool_node_count
    vm_size         = "Standard_B2ms"
    os_disk_size_gb = 30
    max_pods        = 30
  }

  addon_profile {
    http_application_routing {
      enabled = true
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
  name                = "${terraform.workspace}-app"
  zone_name           = data.azurerm_dns_zone.dns_zone.name
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  ttl                 = 300
  record              = "parrot.${azurerm_kubernetes_cluster.aks.addon_profile.0.http_application_routing[0].http_application_routing_zone_name}"
}

#######################
#### K8s Resources ####
#######################

### Tiller SA & CRB (For Helm Installation, until Helm Provider Supports Helm 3. See: https://github.com/terraform-providers/terraform-provider-helm/issues/299)

resource "kubernetes_service_account" "tiller_sa" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller_sa_cluster_admin_rb" {
  metadata {
    name = "tiller-cluster-role"
  }
  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tiller_sa.metadata.0.name
    namespace = "kube-system"
    api_group = ""
  }
}

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

### Get ACR Data

data "helm_repository" "repo" {
  name     = var.repo_name
  url      = "https://${var.repo_name}.azurecr.io/helm/v1/repo"
  username = var.repo_username
  password = var.repo_password
}

### Define Parrot additional values to be passed as inputs to the chart

locals {
  parrot_values = {
    "ingress.basedomain" = azurerm_kubernetes_cluster.aks.addon_profile.0.http_application_routing[0].http_application_routing_zone_name
  }
}

### Create helm releases for each app in var.apps

resource "helm_release" "phippyandfriends" {
  for_each   = var.apps
  name       = each.key
  repository = data.helm_repository.repo.metadata[0].name
  chart      = each.key
  namespace  = kubernetes_namespace.phippyandfriends.metadata.0.name
  version    = lookup(each.value, "version") != "" ? lookup(each.value, "version") : null

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
    kubernetes_cluster_role_binding.tiller_sa_cluster_admin_rb,
    kubernetes_service_account.tiller_sa,
    kubernetes_cluster_role_binding.default_view
  ]
}
