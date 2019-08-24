resource_group_name = "demo"

vnet_name = "demo"

subnets = {
  subnet-1 = {
    name              = "aks-subnet"
    cidr              = "10.0.0.0/22",
    service_endpoints = ["Microsoft.KeyVault"]
  }
  subnet-2 = {
    name              = "vk-subnet",
    cidr              = "10.0.8.0/22",
    service_endpoints = []
  }
}