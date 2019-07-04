## Values to initialize the environment. No resource Creation

provider "azurerm" {
  version = "~> 1.2"
}

provider "random" {
  version = "~> 2.0"
}

provider "template" {
  version = "~> 2.1"
}

provider "null" {
  version = "~> 2.1"
}

terraform {
  required_version = ">= 0.12"
  backend "azurerm" {}
}

