terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    azuredevops = { # To create AZ Devops pipelines and connections
      source  = "microsoft/azuredevops"
    }
    azuread = { # To enable google login
      source  = "hashicorp/azuread"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.SUBSCRIPTION
  resource_provider_registrations = "core"
}

provider "azuredevops" {
  org_service_url = var.AZ_DEVOPS_ORG
  personal_access_token = var.AZ_DEVOPS_TOKEN
}