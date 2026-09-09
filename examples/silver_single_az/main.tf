terraform {
  required_version = "~> 1.5"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.12.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.4.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = "true"
  features {}
}

locals {
  enable_telemetry = true
  location         = "eastus"
  tags = {
    scenario         = "Default"
    project          = "Oracle Database @ Azure"
    createdby        = "ODAA Infra - AVM Module"
    delete           = "yes"
    deploy_timestamp = timestamp()
  }
  zone = "3"
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# Create SSH Keys for deployment of ODAA VM cluster

resource "tls_private_key" "generated_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azapi_resource" "ssh_public_key" {
  location  = local.location
  name      = "odaa_ssh_key"
  parent_id = azurerm_resource_group.this.id
  type      = "Microsoft.Compute/sshPublicKeys@2023-09-01"
  body = {
    properties = {
      publicKey = tls_private_key.generated_ssh_key.public_key_openssh
    }
  }
}

resource "local_file" "private_key" {
  filename = "path.module/id_rsa"
  content  = tls_private_key.generated_ssh_key.private_key_pem
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

# Create a Resource group that will host all the pattern resources
resource "azurerm_resource_group" "this" {
  location = local.location
  name     = module.naming.resource_group.name_unique
}

# Create a Log analytics resource for use in Vnet diagnostics
resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

# Single-AZ Deployment of ODAA infrastructure/VM Cluster (Silver)
module "silver_single_az" {
  source = "../../"

  # Create the ODAA Infrastructure resource(s)
  cloud_exadata_infrastructure = {
    primary_exadata_infrastructure = {

      location                             = azurerm_resource_group.this.location
      name                                 = "odaa-infra-${random_string.suffix.result}"
      display_name                         = "odaa-infra-${random_string.suffix.result}"
      resource_group_id                    = azurerm_resource_group.this.id
      zone                                 = local.zone
      compute_count                        = 2
      storage_count                        = 3
      shape                                = "Exadata.X9M"
      maintenance_window_leadtime_in_weeks = 0
      maintenance_window_preference        = "NoPreference"
      maintenance_window_patching_mode     = "Rolling"
      tags                                 = local.tags
      enable_telemetry                     = local.enable_telemetry
    }
  }
  # Create the VM Cluster resource(s)
  cloud_exadata_vm_cluster = {
    primary_vm_cluster = {
      location                     = azurerm_resource_group.this.location
      resource_group_id            = azurerm_resource_group.this.id
      cloud_exadata_infra_name     = "primary_exadata_infrastructure"
      vnet_name                    = "primaryvnet"
      client_subnet_name           = "client"
      backup_subnet_cidr           = "172.17.5.0/24"
      ssh_public_keys              = [tls_private_key.generated_ssh_key.public_key_openssh]
      cluster_name                 = "odaa-vmcl"
      display_name                 = "odaa vm cluster"
      data_storage_size_in_tbs     = 2
      dbnode_storage_size_in_gbs   = 120
      time_zone                    = "UTC"
      memory_size_in_gbs           = 60
      hostname                     = "hostname-${random_string.suffix.result}"
      cpu_core_count               = 4
      data_storage_percentage      = 80
      is_local_backup_enabled      = false
      is_sparse_diskgroup_enabled  = false
      license_model                = "LicenseIncluded"
      gi_version                   = "19.0.0.0"
      is_diagnostic_events_enabled = true
      is_health_monitoring_enabled = true
      is_incident_logs_enabled     = true
      tags                         = local.tags
      enable_telemetry             = var.enable_telemetry
    }
  }
  location = azurerm_resource_group.this.location
  # No peerings, only one vnet
  odaa_vnet_peerings  = {}
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry # see variables.tf
  # Create the Virtual Networks
  virtual_networks = {
    primaryvnet = {
      name          = module.naming.virtual_network.name_unique
      address_space = ["10.0.0.0/16"]
      subnet = [
        {
          name               = "client"
          address_prefixes   = ["10.0.0.0/24"]
          delegate_to_oracle = true
      }]
      diagnostic_settings = {
        sendToLogAnalytics = {
          name                           = "sendToLogAnalytics"
          workspace_resource_id          = azurerm_log_analytics_workspace.this.id
          log_analytics_destination_type = "Dedicated"
        }
      }
    }
  }
}
