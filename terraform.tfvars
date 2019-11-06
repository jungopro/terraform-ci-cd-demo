resource_group_name = "demo"

vnet_name = "demo"

subnets = {
  subnet-1 = {
    name              = "aks-subnet"
    cidr              = "172.16.0.0/22",
    service_endpoints = ["Microsoft.KeyVault"]
  }
  subnet-2 = {
    name              = "vk-subnet",
    cidr              = "172.16.8.0/22",
    service_endpoints = []
  }
}

k8s_version = "1.14.8"

profiles = {
  default = {
    name  = "default"
    count = 1
    vm_size         = "Standard_B2ms"
    os_type         = "Linux"
    os_disk_size_gb = 30
    max_pods        = 30
  }
  gpu = {
    name  = "gpu"
    count = 1
    vm_size         = "Standard_NC6_Promo"
    os_type         = "Linux"
    os_disk_size_gb = 30
    max_pods        = 30
  }
}