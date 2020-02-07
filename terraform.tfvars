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

k8s_version = "1.15.7"

apps = {
  parrot = {
    version = "v0.5.0"
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
