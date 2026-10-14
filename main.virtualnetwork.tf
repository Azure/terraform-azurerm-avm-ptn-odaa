# Create the virtual networks, delegate the specified subnets to Oracle RP
module "odaa_vnets" {
  source   = "Azure/avm-res-network-virtualnetwork/azurerm"
  version  = "0.6.0"
  for_each = var.virtual_networks

  address_space       = each.value.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  name                = each.value.name
  subnets = { for idx, item in each.value.subnet :
    item.name => {
      name                            = item.name
      address_prefixes                = item.address_prefixes
      default_outbound_access_enabled = true
      delegation = item.delegate_to_oracle ? [
        {
          name = item.name
          service_delegation = {
            name = "Oracle.Database/networkAttachments"
          }
        }
      ] : []
    }
  }
  tags = var.tags
}

# Setup peetings between virtual networks, if specified
module "vnet_peerings" {
  source = "./modules/vnet_peerings"
  providers = {
    azapi   = azapi
    azurerm = azurerm
  }
  for_each = var.odaa_vnet_peerings

  primary_vnet_name             = each.value.vnet_source_name
  primary_vnet_resource_group   = each.value.vnet_source_resource_group
  secondary_vnet_name           = each.value.vnet_destination_name
  secondary_vnet_resource_group = each.value.vnet_destination_resource_group

  depends_on = [module.odaa_vnets]
}
