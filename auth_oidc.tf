# Auth methods
module "oidc" {
  source = "github.com/grantorchard/terraform-vault-module-oidc"

  azure_tenant_id    = local.azure_tenant_id
  oidc_client_id     = local.oidc_client_id
  oidc_client_secret = local.oidc_client_secret
  web_redirect_uri   = "${var.vault_url}/ui/vault/auth/oidc/callback"
}