variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "csp_url" {
  description = "Infoblox CSP URL"
  type        = string
  sensitive   = true
}

variable "api_key" {
  description = "Infoblox API Key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Azure Region for the VNET"
  type        = string
}

variable "resource_group" {
  description = "Azure Resource Group Name"
  type        = string
}

variable "infoblox_address_block_name" {
  description = "Name of the Address Block in Infoblox"
  type        = string
}

variable "vnet_prefix" {
  description = "Prefix for the VNET"
  type        = string
}

variable "vnets" {
  description = "List of VNET names"
  type        = list(string)
}

variable "subnet_cidr" {
  description = "Subnet size (CIDR e.g. /24)"
  type        = string
}

variable "subnet_comment" {
  description = "Description for the Infoblox Subnet"
  type        = string
}

variable "subnet_tags" {
  description = "Tags for the subnet"
  type        = map(string)
}