############################
## General Init Variables ##
############################

variable "location" {
  description = "Azure location to create the resource in"
}

variable "tags" {
  type        = map(string)
  description = "list of tags to apply to the resources"
  default     = {}
}

