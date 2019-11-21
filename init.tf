## Values to initialize the environment. No resource Creation

provider "azurerm" {
  version = "~> 1.2"

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

provider "random" {
  version = "~> 2.0"
}

provider "null" {
  version = "~> 2.1.2"
}

provider "template" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.3"
}

provider "kubernetes" {
  version                = "~> 1.8"
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  username               = azurerm_kubernetes_cluster.aks.kube_config.0.username
  password               = azurerm_kubernetes_cluster.aks.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  debug            = true
  version          = "~> 0.10"
  install_tiller   = false
  kubernetes {
    host     = azurerm_kubernetes_cluster.aks.kube_config.0.host
    username = azurerm_kubernetes_cluster.aks.kube_config.0.username
    password = azurerm_kubernetes_cluster.aks.kube_config.0.password

    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}

terraform {
  required_version = ">= 0.12"
  backend "azurerm" {}
}

data "azurerm_client_config" "current" {}