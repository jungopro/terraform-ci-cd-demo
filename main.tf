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
  tags     = merge(local.tags, { "description" = "WAF RG" })
}

module "vnet" {
  source              = "./modules/vnet"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  tags                = merge(local.tags, { "description" = "WAF vNet" })
}
