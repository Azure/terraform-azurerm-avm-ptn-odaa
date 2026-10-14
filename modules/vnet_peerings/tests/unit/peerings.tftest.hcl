mock_provider "azapi" {}
mock_provider "azurerm" {}

override_data {
  target = data.azurerm_virtual_network.vnet_source
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/source"
  }
}

override_data {
  target = data.azurerm_virtual_network.vnet_destination
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/destination"
  }
}

override_resource {
  target = module.peering.azapi_resource.this[0]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/source/virtualNetworkPeerings/source-to-destination"
  }
}

override_resource {
  target = module.peering.azapi_resource.reverse[0]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/destination/virtualNetworkPeerings/destination-to-source"
  }
}

run "forward_and_reverse_ids" {
  command = apply

  providers = {
    azapi   = azapi
    azurerm = azurerm
  }

  variables {
    primary_vnet_name             = "source"
    primary_vnet_resource_group   = "rg-unit"
    secondary_vnet_name           = "destination"
    secondary_vnet_resource_group = "rg-unit"
  }

  assert {
    condition     = output.resource_id == output.vnet_peerings_resource_ids["source-to-destination"]
    error_message = "The primary peering ID must retain its resource_id output."
  }
  assert {
    condition     = length(output.vnet_peerings_resource_ids) == 2 && endswith(output.vnet_peerings_resource_ids["destination-to-source"], "/destination/virtualNetworkPeerings/destination-to-source")
    error_message = "Both forward and reverse peering IDs must be exported by name."
  }
}
