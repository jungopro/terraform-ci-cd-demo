tags = {
  purpose = "infra validation"
  owners  = "devops team"
}

node_pools = {
  cpu = {
    node_count = 1
    vm_size    = "Standard_F2s_v2"
    os_type    = "Linux"
  }
}