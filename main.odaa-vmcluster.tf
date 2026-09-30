# Create Oracle VM Cluster resource

module "odaa_vmcluster" {
  source   = "Azure/avm-res-oracledatabase-cloudvmcluster/azurerm"
  version  = "0.3.2"
  for_each = var.cloud_exadata_vm_cluster

  # Configure the Cloud Infrastructure resource for the cluster
  cloud_exadata_infrastructure_id = module.odaa_infrastructure[each.value.cloud_exadata_infra_name].resource.id
  # Fundamentals
  cluster_name = each.value.cluster_name
  # Compute configuration settings
  cpu_core_count             = each.value.cpu_core_count
  data_storage_size_in_tbs   = each.value.data_storage_size_in_tbs
  dbnode_storage_size_in_gbs = each.value.dbnode_storage_size_in_gbs
  hostname                   = each.value.hostname
  location                   = each.value.location
  memory_size_in_gbs         = each.value.memory_size_in_gbs
  resource_group_id          = data.azurerm_resource_group.odaa_group.id
  ssh_public_keys            = each.value.ssh_public_keys
  subnet_id                  = module.odaa_vnets[each.value.vnet_name].subnets[each.value.client_subnet_name].id
  # Virtual network settings
  vnet_id            = module.odaa_vnets[each.value.vnet_name].virtual_network_id
  backup_subnet_cidr = each.value.backup_subnet_cidr
  # Storage configuration
  data_storage_percentage = each.value.data_storage_percentage
  # Optional settings
  gi_version                   = each.value.gi_version
  is_diagnostic_events_enabled = each.value.is_diagnostic_events_enabled
  is_health_monitoring_enabled = each.value.is_health_monitoring_enabled
  is_incident_logs_enabled     = each.value.is_incident_logs_enabled
  is_local_backup_enabled      = each.value.is_local_backup_enabled
  is_sparse_diskgroup_enabled  = each.value.is_sparse_diskgroup_enabled
  license_model                = each.value.license_model
  nsg_cidrs                    = each.value.nsg_cidrs
  tags                         = each.value.tags
  time_zone                    = each.value.time_zone

  depends_on = [module.odaa_infrastructure]
}
