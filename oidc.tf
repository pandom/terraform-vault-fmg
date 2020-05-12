# Initial bootstrap of the environment for Burkey and Grant to get admin access without the root token.
# We will configure OIDC in order to use our Azure AD accounts for authentication, and assign an admin policy.

resource random_password "azure-oidc" {
  length = 32
  special = true
}

resource azuread_application "azure-oidc" {
  name                       = "oidc-demo"
  reply_urls                 = [
    "http://localhost:8250/oidc/callback",
    "${local.vault_url}/ui/vault/auth/oidc/oidc/callback"
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

resource azuread_application_password "azure-oidc" {
  application_object_id = azuread_application.azure-oidc.id
  value                 = random_password.azure-oidc.result
  end_date              = timeadd(timestamp(), "8766h")
  lifecycle {
    ignore_changes = [end_date]
  }
}

# Initialise OIDC secrets engine and default role

resource vault_jwt_auth_backend "oidc" {
    path = "oidc"
    type = "oidc"
    oidc_discovery_url = "https://login.microsoftonline.com/${data.azurerm_subscription.this.tenant_id}/v2.0"
    oidc_client_id = azuread_application.azure-oidc.application_id
    oidc_client_secret = azuread_application_password.azure-oidc.value
    default_role = "default"
}

resource vault_jwt_auth_backend_role "default" {
  backend         = vault_jwt_auth_backend.oidc.path
  role_name       = "default"
  token_policies  = [
    "default"
  ]
  user_claim            = "email"
  role_type             = "oidc"
  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "${local.vault_url}/ui/vault/auth/oidc/oidc/callback"
  ]
}

resource vault_identity_entity "this" {
  for_each = local.users
  name = each.key
}

resource vault_identity_entity_alias "this" {
  for_each = local.users
  name            = each.value
  mount_accessor  = vault_jwt_auth_backend.oidc.accessor
  canonical_id    = vault_identity_entity.this[each.key].id
}

resource vault_identity_group "this" {
  name     = "admin"
  type     = "internal"
  policies = [
    vault_policy.admin.name
  ]
  member_entity_ids = [
    for v in vault_identity_entity.this : v.id
  ]
}