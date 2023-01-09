terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }

  backend "azurerm" {
    subscription_id      = "8564cd5f-4177-4e5e-8c9e-8932c69ceaa5"
    resource_group_name  = "rg-terraform-github-actions-state"
    storage_account_name = "ghesdeployterraformazure"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true
  }

}

provider "azurerm" {
  features {}
  use_oidc = true
}
