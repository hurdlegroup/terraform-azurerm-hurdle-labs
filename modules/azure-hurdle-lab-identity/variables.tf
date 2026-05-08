variable "subscription_id" {
  description = "Azure subscription ID used for subscription-scoped role assignment."
  type        = string
}

variable "app_display_name" {
  description = "Display name for the app registration."
  type        = string
}

variable "app_secret_display_name" {
  description = "Display name for the app registration secret."
  type        = string
  default     = null
}

variable "app_secret_lifetime" {
  description = "App registration secret lifetime duration in hours, e.g. 4380h for 6 months."
  type        = string
  default     = "4380h"
}

variable "resource_group_id" {
  description = "Resource group ID for assigning Contributor to the service principal."
  type        = string
}
