variable "subscription_id" {
  description = "Azure subscription ID used for subscription-scoped role assignment."
  type        = string
}

variable "app_display_name" {
  description = "Display name for the app registration."
  type        = string
  default     = "app-hurdle-lab"
}

variable "resource_group_id" {
  description = "Resource group ID for assigning Contributor to the service principal."
  type        = string
}
