output "infoblox_api_debug" {
  value = jsondecode(jsonencode(data.bloxone_ipam_next_available_subnets.next_available_subnets))
}