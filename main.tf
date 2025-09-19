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
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

locals {
  prefix       = var.vnet_prefix
  subnet_count = length(var.vnets)

  # Reservierungen pro VNet: .1 (Gateway), .2/.3 (DNS)
  reserved_ip_entries = merge(
    {
      for vnet in var.vnets :
      "${vnet}-1" => { vnet = vnet, offset = 1, comment = "reserved Azure Default Gateway" }
    },
    {
      for vnet in var.vnets :
      "${vnet}-2" => { vnet = vnet, offset = 2, comment = "reserved Azure DNS-IP-Address for virtual Network" }
    },
    {
      for vnet in var.vnets :
      "${vnet}-3" => { vnet = vnet, offset = 3, comment = "reserved Azure DNS-IP-Address for virtual Network" }
    }
  )
}

# Infoblox: Address Block finden
data "bloxone_ipam_address_blocks" "address_block_from_name" {
  filters = {
    name = var.infoblox_address_block_name
  }
}

# N freie Subnetze im Block ermitteln
data "bloxone_ipam_next_available_subnets" "next_available_subnets" {
  id           = data.bloxone_ipam_address_blocks.address_block_from_name.results[0].id
  cidr         = tonumber(replace(var.subnet_cidr, "/", ""))
  subnet_count = local.subnet_count
}

# Map je VNet -> "x.x.x.x/YY"
locals {
  vnet_cidrs = {
    for vnet in var.vnets :
    vnet => format(
      "%s/%s",
      replace(
        trimspace(data.bloxone_ipam_next_available_subnets.next_available_subnets.results[index(var.vnets, vnet)]),
        "\"",
        ""
      ),
      var.subnet_cidr
    )
  }
}

# Azure VNETs
resource "azurerm_virtual_network" "vnets" {
  for_each            = toset(var.vnets)
  name                = "${local.prefix}-${each.value}"
  location            = var.region
  resource_group_name = var.resource_group
  address_space       = [local.vnet_cidrs[each.value]]
}

# Azure Subnets (1:1)
resource "azurerm_subnet" "vnets_subnets" {
  for_each             = toset(var.vnets)
  name                 = "subnet-${azurerm_virtual_network.vnets[each.value].name}"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnets[each.value].name
  address_prefixes     = [local.vnet_cidrs[each.value]]
}

# Infoblox Subnet (implizit nach Azure, via address/cidr Werte)
resource "bloxone_ipam_subnet" "infoblox_subnets" {
  for_each = toset(var.vnets)

  name    = "subnet-${azurerm_virtual_network.vnets[each.value].name}"
  address = cidrhost(local.vnet_cidrs[each.value], 0) # Netzadresse
  cidr    = var.subnet_cidr
  space   = data.bloxone_ipam_address_blocks.address_block_from_name.results[0].space
  comment = var.subnet_comment
  tags    = var.subnet_tags
}

# Reserviere .1, .2, .3 je VNet als Host-Objekte
resource "bloxone_ipam_host" "reserved_ips" {
  for_each = local.reserved_ip_entries

  name = "reserved-${each.key}"

  addresses = [{
    address = cidrhost(local.vnet_cidrs[each.value.vnet], each.value.offset)
    space   = bloxone_ipam_subnet.infoblox_subnets[each.value.vnet].space
  }]

  comment = each.value.comment
  tags    = var.subnet_tags
}
