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

node_pools = {
  pool-1 = {
    node_count = 1
    vm_size    = "Standard_B2ms"
  }
  pool-2 = {
    node_count = 1
    vm_size    = "Standard_A2_v2"
  }
}
