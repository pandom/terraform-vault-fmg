# Reusable variables
locals {
  #Shorthand these to make them easier to refer to
  subscription_id = data.azurerm_subscription.this.subscription_id
  azure_tenant_id = data.azurerm_subscription.this.tenant_id
  oidc_client_id = azuread_application.azure-oidc.application_id
  oidc_client_secret = azuread_application_password.azure-oidc.value

  permitted_ips = ["203.206.6.67","120.158.233.91"]
}

# Azure provider related requirements
provider "azurerm" {
  features {}
}

data azurerm_subscription "this" {}


#Azure App Configuration
resource azuread_application "azure-oidc" {
  name                       = "oidc-demo"
  reply_urls                 = [
    "http://localhost:8250/oidc/callback",
    "${var.vault_url}/ui/vault/auth/oidc/oidc/callback"
  ]

  required_resource_access {
    # Add MS Graph Group.Read.All API permissions
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "5b567255-7703-4780-807c-7be8301ae99b"
      type = "Scope"
    }
  }

  available_to_other_tenants = false
  oauth2_allow_implicit_flow = true
  type                       = "webapp/api"
}

resource random_password "azure-oidc" {
  length = 32
  special = true
}

resource azuread_application_password "azure-oidc" {
  application_object_id = azuread_application.azure-oidc.id
  value                 = random_password.azure-oidc.result
  end_date              = timeadd(timestamp(), "8766h")
  lifecycle {
    ignore_changes = [end_date]
  }
}