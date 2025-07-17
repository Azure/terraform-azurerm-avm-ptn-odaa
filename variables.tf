variable "cloud_exadata_infrastructure" {
  type = map(object({
    name                                 = string
    location                             = string
    zone                                 = string
    compute_count                        = number
    display_name                         = string
    maintenance_window_loadtime_in_weeks = optional(string, 0)
    maintenance_window_preference        = optional(string, "NoPreference")
    maintenance_window_patching_mode     = optional(string, "Rolling")
    shape                                = optional(string, "Exadata.X9M")
    storage_count                        = number
    tags                                 = optional(map(string))
  }))
  description = <<DESCRIPTION
  Cloud Exadata Infrastructure resources  

  - `name` - The name of the Cloud Exadata Infrastructure.
  - `location` - The location of the Cloud Exadata Infrastructure.
  - `zone` - (Optional) The availability zone of the Cloud Exadata Infrastructure.
  - `compute_count` - The number of compute nodes in the Cloud Exadata Infrastructure.
  - `display_name` - The display name of the Cloud Exadata Infrastructure.
  - `maintenance_window_loadtime_in_weeks` - The maintenance window load time in weeks.
  - `maintenance_window_preference` - The maintenance window preference.
  - `maintenance_window_patching_mode` - The maintenance window patching mode.
  - `shape` - The shape of the Cloud Exadata Infrastructure.
  - `storage_count` - The number of storage servers in the Cloud Exadata Infrastructure.
  - `tags` - (Optional) A mapping of tags to assign to the Cloud Exadata Infrastructure.
DESCRIPTION
}

variable "cloud_exadata_vm_cluster" {
  type = map(object({
    cluster_name               = string
    display_name               = string
    cloud_exadata_infra_name   = string
    location                   = string
    data_storage_size_in_tbs   = number
    dbnode_storage_size_in_gbs = number
    hostname                   = string
    cpu_core_count             = number
    data_storage_percentage    = number
    memory_size_in_gbs         = number

    ssh_public_keys = list(string)
    nsg_cidrs = optional(set(object({
      source = string
      destination_port_range = optional(object({
        min = string
        max = string
      }), null)
    })))
    license_model                = optional(string, "LicenseIncluded")
    vnet_name                    = string
    client_subnet_name           = string
    backup_subnet_cidr           = string
    gi_version                   = optional(string, "19.0.0.0")
    time_zone                    = string
    is_local_backup_enabled      = optional(bool, true)
    is_sparse_diskgroup_enabled  = optional(bool, true)
    is_diagnostic_events_enabled = optional(bool, false)
    is_health_monitoring_enabled = optional(bool, false)
    is_incident_logs_enabled     = optional(bool, false)
    tags                         = optional(map(string))
  }))
  description = <<DESCRIPTION
  Cloud Exadata VM Cluster resources

  - `cluster_name` - The name of the Cloud Exadata VM Cluster.
  - `display_name` - The display name of the Cloud Exadata VM Cluster.
  - `data_storage_size_in_tbs` - The data storage size in TBs.
  - `dbnode_storage_size_in_gbs` - The DB node storage size in GBs.
  - `time_zone` - The time zone of the Cloud Exadata VM Cluster.
  - `hostname` - The hostname of the Cloud Exadata VM Cluster.
  - `domain` - The domain of the Cloud Exadata VM Cluster.
  - `cpu_core_count` - The CPU core count of the Cloud Exadata VM Cluster.
  - `ocpu_count` - The OCPU count of the Cloud Exadata VM Cluster.
  - `data_storage_percentage` - The data storage percentage of the Cloud Exadata VM Cluster.
  - `is_local_backup_enabled` - The local backup enabled status of the Cloud Exadata VM Cluster.
  - `cloud_exadata_infra_name` - This is a reference to the Cloud Infrastructure object specified in parameters
  - `is_sparse_diskgroup_enabled` - The sparse diskgroup enabled status of the Cloud Exadata VM Cluster.
  - `ssh_public_keys` - The SSH public keys of the Cloud Exadata VM Cluster.
  - `nsg_cidrs` - (Optional) A set of NSG CIDRs of the Cloud Exadata VM Cluster.
  - `license_model` - The license model of the Cloud Exadata VM Cluster.
  - `vnet_name` - This is a reference to the VNET object specified in the Virtual networks parameter
  - `client_subnet_name` - This is a reference to the Subnet object specified in the Subnet attribute in Vnet parameters
  - `gi_version` - The GI version of the Cloud Exadata VM Cluster.
  - `backup_subnet_cidr` - The backup subnet CIDR of the Cloud Exadata VM Cluster.
  - `is_diagnostic_events_enabled` - (Optional) The diagnostic events enabled status of the Cloud Exadata VM Cluster.
  - `is_health_monitoring_enabled` - (Optional) The health monitoring enabled status of the Cloud Exadata VM Cluster.
  - `is_incident_logs_enabled` - (Optional) The incident logs enabled status of the Cloud Exadata VM Cluster.

DESCRIPTION
}

variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

# Set of Virtual network peerings to be setup
variable "odaa_vnet_peerings" {
  type = map(object({
    vnet_source_resource_group      = string
    vnet_destination_resource_group = string
    vnet_source_name                = string
    vnet_destination_name           = string
    }
  ))
  description = "List of virtual network peerings to be setup"
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

# tflint-ignore: terraform_unused_declarations
variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

# Virtual networks for hosting the Exadata appliance(s). They are provisioned with 
# AVM modules for Vnets, and the interface resembles the same.
variable "virtual_networks" {
  type = map(object({
    address_space = list(string)
    name          = string
    ddos_protection_plan = optional(object({
      enable = bool
      id     = string
    }), null)
    encryption = optional(object({
      enforcement = string
    }), null)
    flow_timeout_in_minutes = optional(number, null)
    resource_group_name     = optional(string, null)
    subnet = optional(set(object({
      delegate_to_oracle = bool
      address_prefixes   = list(string)
      name               = string
      security_group     = optional(string, null)
    })), null)
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), null)
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
  }))
  default = {
    primaryvnet = {
      name          = "vnet-odaa"
      address_space = ["10.0.0.0/16"]
      subnet = [
        {
          name               = "client"
          address_prefixes   = ["10.0.0.0/24"]
          delegate_to_oracle = true
        },
        {
          name               = "backup"
          address_prefixes   = ["10.0.1.0/24"]
          delegate_to_oracle = false
      }]
    }
  }
  description = "Virtual Network(s) for hosting Exadata appliances"
}
