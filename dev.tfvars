tags = {
  purpose = "developers environment"
  owners  = "dev team"
}

default_pool_node_count = 2

node_pools = {
  cpu = {
    node_count = 1
    vm_size    = "Standard_F2s_v2"
    os_type    = "Linux"
  }
}