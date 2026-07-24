terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.47.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  # This module disables AzureRM's automatic Resource Provider registration so infrastructure operators do not need subscription-level `*/register/action` permission.
  # A suitably authorised subscription administrator must register any Resource Providers required by the chosen lab topology before Terraform runs.
  # This is intentional least-privilege behaviour; an unregistered provider may instead appear as a misleading Azure API-version error.
  resource_provider_registrations = "none"
}

provider "azuread" {
  tenant_id = var.tenant_id
}
