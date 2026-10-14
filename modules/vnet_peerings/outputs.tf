output "resource_id" {
  description = "Resource ID of the first peering resource"
  value       = module.peering.resource_id
}

output "vnet_peerings_resource_ids" {
  description = "Resource IDs of the Virtual network peerings created"
  value = {
    (module.peering.name)         = module.peering.resource_id
    (module.peering.reverse_name) = module.peering.reverse_resource_id
  }
}
