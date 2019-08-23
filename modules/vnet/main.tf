resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  address_space       = "${var.vnet_address_space}"
  tags                = "${var.tags}"
}

resource "azurerm_subnet" "subnet" {
  count                     = "${length(var.subnet_names)}"
  name                      = "${var.resource_group_name}-vnet-${var.subnet_names[count.index]}-subnet"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  resource_group_name       = "${var.resource_group_name}"
  address_prefix            = "${var.subnet_prefixes[count.index]}"
}