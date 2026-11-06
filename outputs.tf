output "odaa_infra_resource_ids" {
  description = "Resource IDs of the ODAA Infrastructure resources created."
  value       = { for k, v in module.odaa_infrastructure : k => v.resource_id }
}

output "odaa_vmcluster_resource_ids" {
  description = "Resource IDs of the ODAA VM Cluster resources created."
  value       = { for k, v in module.odaa_vmcluster : k => v.resource_id }
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "odaa_vnets_resource_ids" {
  description = "Resource IDs of the Virtual networks created"
  value       = { for k, v in module.odaa_vnets : k => v.resource_id }
}

output "resource_id" {
  description = "Resource ID for tflint compliance"
  value       = values(module.odaa_infrastructure)[0].resource_id
}
