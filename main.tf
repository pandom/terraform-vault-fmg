# Provider related requirements
provider "azurerm" {
  features {}
}

data azurerm_subscription "this" {}

# Reusable variables
locals {
  vault_url = "http://azure-vault.go.hashidemos.io:8200"
  users = {
    "grant":"go@hashicorp.com",
    "burkey":"burkey@hashicorp.com"
  }
}