output "kube_config_raw" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "http_application_routing_zone_name" {
  value = azurerm_kubernetes_cluster.aks.addon_profile.0.http_application_routing[0].http_application_routing_zone_name
}