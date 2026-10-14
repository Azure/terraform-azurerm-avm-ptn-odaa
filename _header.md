# Oracle Exadata appliance deployment on Azure - Pattern module

This pattern module deploys an Oracle Exadata appliance on Azure, with a virtual network and other supporting resources necessary.

It deploys at a minimum the following resources:

- A Virtual network for hosting the Exadata cluster
- An Oracle Cloud Infrastructure resource - with a default configuration
- An Oracle VM Cluster to be deployed on the Oracle Cloud Infrastructure resource

Limitations: This module does not currently handle updates to the Oracle resources, since the underlying resource providers(REST API) do not support Update operations. Hence idempotency is not currently implemented.

## Upgrading existing deployments

This upgrade requires Terraform 1.9 or later, AzAPI 2.12 or later (below 3.0), and AzureRM 4.x. It uses Exadata infrastructure module `0.3.0`, VM cluster module `0.3.1`, and virtual network/peering module `0.6.0`.

**Do not apply this upgrade to existing deployments before migrating the virtual network and subnet state.** The network dependency changes providers and moves each subnet into a child module. Keeping the same Azure resource IDs does not preserve the Terraform addresses.

The following addresses are relative to this pattern module; retain your caller's module prefix and every existing map key:

| Previous address | New address |
| --- | --- |
| `module.odaa_vnets["<vnet-key>"].azurerm_virtual_network.vnet` | `module.odaa_vnets["<vnet-key>"].azapi_resource.vnet` |
| `module.odaa_vnets["<vnet-key>"].azurerm_subnet.subnet["<subnet-name>"]` | `module.odaa_vnets["<vnet-key>"].module.subnet["<subnet-name>"].azapi_resource.subnet` |

There is no automatic state migration. Do not use a wildcard `moved` block or a plain cross-provider `terraform state mv`; the providers have different state schemas.

1. Schedule an approved maintenance window and stop all other writers to the same state. While still using the old pattern version, run `terraform state list` and `terraform state show` for every affected address. Record the exact Azure IDs, subnet delegations, address prefixes, network policies and outbound-access settings.
1. Back up the state and retain the previous configuration and lock file. State backups can contain secrets; keep them outside source control in a protected location.
1. Update the pattern version and initialize with `terraform init -upgrade`. Supply the same input values and keys. Review the AzureRM 4 upgrade requirements, including subscription configuration.
1. For each VNet, remove only its old state entry and import the existing Azure resource at its new address. Repeat for **every** subnet. The PowerShell 7.4 example below assumes the consumer calls this pattern `module.odaa`; replace all example keys and IDs with the values recorded from your own state.

   ```powershell
   $oldVnet = 'module.odaa.module.odaa_vnets["primaryvnet"].azurerm_virtual_network.vnet'
   $newVnet = 'module.odaa.module.odaa_vnets["primaryvnet"].azapi_resource.vnet'
   $oldSubnet = 'module.odaa.module.odaa_vnets["primaryvnet"].azurerm_subnet.subnet["client"]'
   $newSubnet = 'module.odaa.module.odaa_vnets["primaryvnet"].module.subnet["client"].azapi_resource.subnet'
   $vnetId = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<vnet-name>'
   $subnetId = "$vnetId/subnets/<subnet-name>"

   terraform state rm $oldVnet
   if ($LASTEXITCODE -ne 0) { throw 'VNet state removal failed; stop the migration.' }
   terraform import $newVnet "${vnetId}?api-version=2023-11-01"
   if ($LASTEXITCODE -ne 0) { throw 'VNet import failed; do not apply.' }
   terraform state rm $oldSubnet
   if ($LASTEXITCODE -ne 0) { throw 'Subnet state removal failed; stop the migration.' }
   terraform import $newSubnet "${subnetId}?api-version=2023-11-01"
   if ($LASTEXITCODE -ne 0) { throw 'Subnet import failed; do not apply.' }
   ```

   `state rm` forgets Terraform ownership; it does not delete the Azure resource. Do not apply between removal and successful import. If an import fails, stop and recover using your backend's state-restoration procedure and protected backup before resuming. Imports can read other configured resources and require the appropriate existing identity; they are not offline operations.
1. Inspect `terraform state list` and run a normal plan. Require **zero unintended destroys or replacements**, unchanged resource IDs and outputs, and matching network settings before approving an apply. Stop on any unexplained Oracle update: the Oracle modules retain their resource addresses but change the resource API from `2023-09-01` to `2025-03-01`, including maintenance/SCAN-listener defaults. Their live upgrade behavior has not been validated by mocked tests.

The pattern's input map shapes and resource-ID output names are unchanged. Oracle delegation still targets `Oracle.Database/networkAttachments`; the network module now obtains delegation actions from the service. Default subnet outbound access is explicitly kept enabled to match the previous module/provider default. Existing peering resource addresses and traffic/gateway settings are retained; they do not require the VNet/subnet state conversion. If you have separately customized dependency resources, inventory and review their state changes before proceeding.


> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
> 
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
> 
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.
