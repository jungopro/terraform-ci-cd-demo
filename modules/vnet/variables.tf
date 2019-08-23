variable "resource_group_name" {
  description = "(Required) The name of the resource group in which to create the storage account. Changing this forces a new resource to be created"
}

variable "location" {
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created"
}

variable "vnet_address_space" {
  type = "list"
  description = "The address space that is used the virtual network. You can supply more than one address space. Changing this forces a new resource to be created"
  default = ["10.0.0.0/8"]
}

variable "subnet_prefixes" {
  description = "The address prefix to use for the subnet."
  default     = ["10.0.10.0/24", "10.0.100.0/24"]
}

variable "subnet_names" {
  description = "A list of subnets inside the vNet"
  default     = ["backend", "frontend"]
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the resource"
  default = {}
}