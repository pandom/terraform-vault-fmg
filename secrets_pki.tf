resource vault_mount "pki" {
  path = "pki"
  type = "pki"
}

resource vault_pki_secret_backend_root_cert "ca" {
  backend = vault_mount.pki.path

  type = "internal"
  common_name = "azure-vault.go.hashidemos.io"
  ttl = "315360000"
  format = "pem"
  private_key_format = "der"
  key_type = "rsa"
  key_bits = 4096
  exclude_cn_from_sans = true
  ou = "SE"
  organization = "HashiCorp"
}


resource vault_pki_secret_backend_config_urls "ca_config_urls" {
  backend              = vault_mount.pki.path
  issuing_certificates = [
    "${var.vault_url}/v1/pki/ca",

  ]
}

resource vault_pki_secret_backend_role "nginx" {
  backend = vault_mount.pki.path
  name    = "nginx"
  allow_subdomains = true
  allow_any_name = false
  key_usage = [
    "DigitalSignature",
    "KeyAgreement",
    "KeyEncipherment",
  ]
  ttl = "300"
  max_ttl = "1800"
}

resource "vault_policy" "pki_rotate" {
  name = "pki_rotate"

  policy = file("${path.module}/policies/pki_rotate.hcl")
}