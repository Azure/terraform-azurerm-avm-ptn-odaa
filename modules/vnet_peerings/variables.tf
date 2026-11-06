variable "location" {
  type        = string
  description = "The Azure region for this module's resources or telemetry deployment."
  nullable    = false

  validation {
    condition     = !var.enable_telemetry || var.location != null
    error_message = "The location must not be null when telemetry is enabled."
  }
}

variable "primary_vnet_name" {
  type        = string
  description = "Name of the source vnet"
}

variable "primary_vnet_resource_group" {
  type        = string
  description = "Name of the resource group of source vnet"
}

variable "secondary_vnet_name" {
  type        = string
  description = "Name of the destination vnet"
}

variable "secondary_vnet_resource_group" {
  type        = string
  description = "Name of the resource group of destination vnet"
}

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
