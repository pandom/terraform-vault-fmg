# Provider related requirements
provider "azurerm" {
  features {}
}

data azurerm_subscription "this" {}

# Reusable variables
locals {
  vault_url = data.terraform_remote_state.this.outputs.vault_url
  users = {
    "grant":"go@hashicorp.com",
    "burkey":"burkey@hashicorp.com"
  }
}