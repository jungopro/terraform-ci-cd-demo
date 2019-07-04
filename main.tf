locals {
  tags = "${merge("${var.tags}", map("terraform workspace", "${terraform.workspace}"))}"
}

resource "azurerm_resource_group" "esource_group" {
  name     = "${terraform.workspace}-rg"
  location = "${var.location}"
  tags     = "${merge("${local.tags}")}"
}
