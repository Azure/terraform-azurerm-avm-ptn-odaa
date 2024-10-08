<!-- BEGIN_TF_DOCS -->
# Single-AZ deployment (Silver)

This example deploys an Oracle exadata appliance, with a virtual network to support it.  All resources are deployed in a single Availability zone, with no redundancy.

It deploys the following resources

- A Log Analytics workspace for collecting logs/metrics from vnet
- A Virtual network for hosting the Exadata cluster
- An Oracle Cloud Infrastructure resource - with a default configuration
- An Oracle VM Cluster to be deployed on the Oracle Cloud Infrastructure resource

```hcl
terraform {
  required_version = "~> 1.5"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.14.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
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
  type = "Microsoft.Compute/sshPublicKeys@2023-09-01"
  body = {
    properties = {
      publicKey = tls_private_key.generated_ssh_key.public_key_openssh
    }
  }
  location  = local.location
  name      = "odaa_ssh_key"
  parent_id = azurerm_resource_group.this.id
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
  source              = "../../"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

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

  # No peerings, only one vnet
  odaa_vnet_peerings = {}

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

  enable_telemetry = var.enable_telemetry # see variables.tf

}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 1.14.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.74)

- <a name="requirement_local"></a> [local](#requirement\_local) (2.5.1)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

- <a name="requirement_tls"></a> [tls](#requirement\_tls) (4.0.5)

## Resources

The following resources are used by this module:

- [azapi_resource.ssh_public_key](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [local_file.private_key](https://registry.terraform.io/providers/hashicorp/local/2.5.1/docs/resources/file) (resource)
- [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [tls_private_key.generated_ssh_key](https://registry.terraform.io/providers/hashicorp/tls/4.0.5/docs/resources/private_key) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_silver_single_az"></a> [silver\_single\_az](#module\_silver\_single\_az)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->