resource_group_name = "demo"

vnet_name = "demo"

subnets = {
  aks-subnet = {
    cidr              = "172.16.0.0/22",
    service_endpoints = ["Microsoft.KeyVault"]
  }
  vk-subnet = {
    cidr              = "172.16.8.0/22",
    service_endpoints = []
  }
}

k8s_version = "1.14.8"

node_pools = {
  cpu = {
    node_count = 1
    vm_size    = "Standard_F2s_v2"
    os_type    = "Linux"
  }
}

repo_name = "jungo"

apps = {
  parrot = {
    version = "v0.3.0"
}
  captainkube = {
    version = "v0.4.0"
  }
  nodebrady = {
    version = "v0.3.0"
  }
  phippy = {
    version = "v0.3.0"
  }
}
