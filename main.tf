locals {
  tags = merge(
    var.tags,
    {
      "terraform workspace" = terraform.workspace
    },
  )
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${terraform.workspace}-rg"
  location = var.location
  tags     = merge(local.tags)
}