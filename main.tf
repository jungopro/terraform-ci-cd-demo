locals {
  tags = merge(var.tags, { "workspace" = "${terraform.workspace}" })
}

#######################
### Azure Resources ###
#######################

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = "${terraform.workspace}-${var.resource_group_name}"
  location = var.resource_group_location

  tags = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${terraform.workspace}-${var.vnet_name}"
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  address_space       = var.vnet_cidr
  location            = var.create_resource_group ? azurerm_resource_group.rg[0].location : var.resource_group_location
  dns_servers         = var.vnet_dns_servers
  tags                = local.tags
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

resource "azurerm_lb" "lb" {
  name                = "${terraform.workspace}-lb"
  location            = var.create_resource_group ? azurerm_resource_group.rg[0].location : var.resource_group_location
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  tags                = local.tags

  frontend_ip_configuration {
    name                 = azurerm_public_ip.pip.name
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}


#######################
#### K8s Resources ####
#######################

/*resource "kubernetes_service_account" "tiller_sa" {
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
}*/

resource "local_file" "kubeconfig" {
  # kube config
  filename = "$HOME/.kube/config"
  content  = azurerm_kubernetes_cluster.aks.kube_config_raw

  # helm init
  provisioner "local-exec" {
    command = "curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh; chmod 700 get_helm.sh; ./get_helm.sh; helm repo add stable https://kubernetes-charts.storage.googleapis.com/; helm repo update"
    environment = {
      KUBECONFIG = "$HOME/.kube/config"
    }
  }
}

resource "helm_release" "ingress" {
  name      = "ingress"
  chart     = "stable/nginx-ingress"
  namespace = "kube-system"
  timeout   = 1800

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.pip.ip_address
  }
  set {
    name  = "controller.service.annotations.\"service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group\""
    value = azurerm_kubernetes_cluster.aks.node_resource_group
  }
}