resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

# data "azurerm_client_config" "current" {}

# data "azurerm_resource_group" "rg" {
#   name = var.resource_group_name
# }


# data "azapi_resource" "odaa_infra" {
#   depends_on = [ module.odaa_infrastructure ]
#   for_each = module.odaa_infrastructure

#   type      = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
#   parent_id = data.azurerm_resource_group.rg.id
#   name      = each.value.name
# }
