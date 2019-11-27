output "kube_config_raw" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "kubeconfig" {
  value =  "./${terraform.workspace}-config.yaml"
}