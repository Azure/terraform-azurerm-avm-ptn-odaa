mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
  mock_data "azapi_resource_list" {
    defaults = {
      output = { value = [] }
    }
  }
  mock_resource "azapi_resource" {
    defaults = {
      output = { properties = { ocid = "unit-test-only" } }
    }
  }
}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
  mock_data "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit"
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}

override_resource {
  target = module.odaa_infrastructure["primary"].azapi_resource.odaa_infra
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Oracle.Database/cloudExadataInfrastructures/infra-unit"
  }
}

override_resource {
  target = module.odaa_vmcluster["primary"].azapi_resource.odaa_vm_cluster
  values = {
    id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Oracle.Database/cloudVmClusters/cl-unit"
    output = { properties = { ocid = "unit-test-only" } }
  }
}

override_resource {
  target = module.odaa_vnets["primaryvnet"].azapi_resource.vnet
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit"
  }
}

override_resource {
  target = module.odaa_vnets["primaryvnet"].module.subnet["client"].azapi_resource.subnet
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/client"
  }
}

variables {
  enable_telemetry    = false
  location            = "eastus"
  resource_group_name = "rg-unit"
  odaa_vnet_peerings  = {}
  cloud_exadata_infrastructure = {
    primary = {
      name          = "infra-unit"
      location      = "eastus"
      zone          = "3"
      compute_count = 2
      storage_count = 3
      display_name  = "infra-unit"
    }
  }
  cloud_exadata_vm_cluster = {
    primary = {
      cluster_name               = "cl-unit"
      display_name               = "cl-unit"
      cloud_exadata_infra_name   = "primary"
      location                   = "eastus"
      data_storage_size_in_tbs   = 2
      dbnode_storage_size_in_gbs = 120
      hostname                   = "host-unit"
      cpu_core_count             = 4
      data_storage_percentage    = 80
      memory_size_in_gbs         = 60
      ssh_public_keys            = ["ssh-rsa unit-test-public-key"]
      vnet_name                  = "primaryvnet"
      client_subnet_name         = "client"
      backup_subnet_cidr         = "10.0.1.0/24"
      time_zone                  = "UTC"
    }
  }
  virtual_networks = {
    primaryvnet = {
      name          = "vnet-unit"
      address_space = ["10.0.0.0/16"]
      subnet = [
        { name = "client", address_prefixes = ["10.0.0.0/24"], delegate_to_oracle = true },
        { name = "backup", address_prefixes = ["10.0.1.0/24"], delegate_to_oracle = false }
      ]
    }
  }
}

run "network_and_oracle_wiring" {
  command = apply

  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }

  assert {
    condition     = output.odaa_vnets_resource_ids["primaryvnet"] == module.odaa_vnets["primaryvnet"].resource_id
    error_message = "The existing VNet output must retain its map key and return the new dependency's resource ID."
  }
  assert {
    condition     = module.odaa_vmcluster["primary"].resource.body.properties.vnetId == output.odaa_vnets_resource_ids["primaryvnet"] && module.odaa_vmcluster["primary"].resource.body.properties.subnetId == module.odaa_vnets["primaryvnet"].subnets["client"].resource_id
    error_message = "The VM cluster must receive the VNet and client subnet resource IDs."
  }
  assert {
    condition     = module.odaa_vmcluster["primary"].resource.body.properties.cloudExadataInfrastructureId == output.odaa_infra_resource_ids["primary"]
    error_message = "The VM cluster must retain its reference to the matching Exadata infrastructure."
  }
  assert {
    condition     = module.odaa_vnets["primaryvnet"].subnets["client"].resource.body.properties.delegations[0].properties.serviceName == "Oracle.Database/networkAttachments" && length(module.odaa_vnets["primaryvnet"].subnets["backup"].resource.body.properties.delegations) == 0
    error_message = "Oracle delegation must apply only to the selected client subnet."
  }
  assert {
    condition     = alltrue([for subnet in module.odaa_vnets["primaryvnet"].subnets : subnet.resource.body.properties.defaultOutboundAccess])
    error_message = "The dependency update must preserve the old provider's enabled default outbound access."
  }
  assert {
    condition     = output.resource_id == output.odaa_infra_resource_ids["primary"] && output.odaa_vmcluster_resource_ids["primary"] == module.odaa_vmcluster["primary"].resource_id
    error_message = "Existing Oracle resource-ID outputs must preserve their values and map keys."
  }
}
