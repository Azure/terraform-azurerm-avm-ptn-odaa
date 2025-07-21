# Create Oracle Infra resource

data "azurerm_resource_group" "odaa_group" {
  name = var.resource_group_name
}
module "odaa_infrastructure" {
  source   = "Azure/avm-res-oracledatabase-cloudexadatainfrastructure/azurerm"
  version  = "0.1.0"
  for_each = var.cloud_exadata_infrastructure

  compute_count = each.value.compute_count
  display_name  = each.value.display_name
  location      = each.value.location
  # Fundamentals
  name              = each.value.name
  resource_group_id = data.azurerm_resource_group.odaa_group.id
  storage_count     = each.value.storage_count
  zone              = each.value.zone
  # Optional configuration
  enable_telemetry                     = false
  maintenance_window_leadtime_in_weeks = each.value.maintenance_window_loadtime_in_weeks
  maintenance_window_patching_mode     = each.value.maintenance_window_patching_mode
  maintenance_window_preference        = each.value.maintenance_window_preference
  shape                                = each.value.shape
  tags                                 = each.value.tags
}
