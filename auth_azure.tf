resource vault_auth_backend "azure" {
  type = "azure"
}

resource vault_azure_auth_backend_config "this" {
  backend       = vault_auth_backend.azure.path
  tenant_id     = local.azure_tenant_id
  resource      = "https://management.azure.com"
}

resource vault_azure_auth_backend_role "this" {
  backend                         = vault_auth_backend.azure.path
  role                            = "kv_reader"
  bound_subscription_ids          = [local.subscription_id]
  bound_resource_groups           = ["kv_reader"]
  bound_locations                 = ["australiaeast"]
  token_ttl                       = 60
  token_max_ttl                   = 120
  token_policies                  = ["kv_reader","pki_rotate"]
}