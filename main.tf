terraform {
  required_providers {
    bloxone = {
      source  = "infobloxopen/bloxone"
      version = ">= 0.7.2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "bloxone" {
  csp_url = var.csp_url
  api_key = var.api_key
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  prefix       = var.vnet_prefix
  subnet_count = length(var.vnets)

  reserved_ip_entries = merge(
    {
      for vnet in var.vnets :
      "${vnet}-1" => {
        vnet    = vnet
        offset  = 1
        comment = "reserved Azure Default Gateway"
      }
    },
    {
      for vnet in var.vnets :
      "${vnet}-2" => {
        vnet    = vnet
        offset  = 2
        comment = "reserved Azure DNS-IP-Address for virtual Network"
      }
    },
    {
      for vnet in var.vnets :
      "${vnet}-3" => {
        vnet    = vnet
        offset  = 3
        comment = "reserved Azure DNS-IP-Address for virtual Network"
      }
    }
  )
}

data "bloxone_ipam_address_blocks" "address_block_from_name" {
  filters = {
    name = var.infoblox_address_block_name
  }
}

data "bloxone_ipam_next_available_subnets" "next_available_subnets" {
  id           = data.bloxone_ipam_address_blocks.address_block_from_name.results[0].id
  cidr         = tonumber(replace(var.subnet_cidr, "/", ""))
  subnet_count = local.subnet_count
}

resource "azurerm_virtual_network" "vnets" {
  for_each            = toset(var.vnets)
  name                = "${local.prefix}-${each.value}"  
  location            = var.region
  resource_group_name = var.resource_group
  address_space       = ["${replace(trimspace(data.bloxone_ipam_next_available_subnets.next_available_subnets.results[index(var.vnets, each.value)]), "\"", "")}/${var.subnet_cidr}"]
}

resource "azurerm_subnet" "vnets_subnets" {
  for_each             = toset(var.vnets)
  name                 = "subnet-${azurerm_virtual_network.vnets[each.value].name}"  
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnets[each.value].name
  address_prefixes     = ["${replace(trimspace(data.bloxone_ipam_next_available_subnets.next_available_subnets.results[index(var.vnets, each.value)]), "\"", "")}/${var.subnet_cidr}"]
}

resource "time_sleep" "wait_for_subnet" {
  depends_on      = [azurerm_subnet.vnets_subnets]
  create_duration = "5s"
}

resource "bloxone_ipam_subnet" "infoblox_subnets" {
  for_each = toset(var.vnets)

  name    = "subnet-${azurerm_virtual_network.vnets[each.value].name}"
  address = replace(trimspace(data.bloxone_ipam_next_available_subnets.next_available_subnets.results[index(var.vnets, each.value)]), "\"", "")
  cidr    = var.subnet_cidr
  space   = data.bloxone_ipam_address_blocks.address_block_from_name.results[0].space
  comment = var.subnet_comment

  tags = var.subnet_tags
}

resource "time_sleep" "wait_for_infoblox" {
  depends_on      = [bloxone_ipam_subnet.infoblox_subnets]
  create_duration = "5s"
}

# Reserviere .1, .2, .3 als „vergeben“ durch Host-Objekte
resource "bloxone_ipam_host" "reserved_ips" {
  for_each = local.reserved_ip_entries

  name = "reserved-${each.key}"

  addresses = [
    {
      address = cidrhost(
        "${bloxone_ipam_subnet.infoblox_subnets[each.value.vnet].address}/${var.subnet_cidr}",
        each.value.offset
      )
      space = data.bloxone_ipam_address_blocks.address_block_from_name.results[0].space
    }
  ]

  comment = each.value.comment
  tags    = var.subnet_tags

  depends_on = [time_sleep.wait_for_infoblox]
}