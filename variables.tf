############################
## General Init Variables ##
############################

variable "subscription_id" {
  description = "Azure Subscription. Define via enviroment variable TF_VAR_subscription_id = <YOUR_SUBSCRIPTION_ID>"
}

variable "tenant_id" {
  description = "Azure Subscription. Define via enviroment variable TF_VAR_tenant_id = <YOUR_TENANT_ID>"
}

variable "client_id" {
  description = "Azure Subscription. Define via enviroment variable TF_VAR_client_id = <YOUR_CLIENT_ID>"
}

variable "client_secret" {
  description = "Azure Subscription. Define via enviroment variable TF_VAR_client_secret = <YOUR_CLIENT_SECRET>"
}

variable "location" {
  description = "Azure location to create the resource in"
}

variable "tags" {
  type        = map(string)
  description = "list of tags to apply to the resources"
  default     = {}
}

