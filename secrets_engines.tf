#  Secrets Engines
## kv-v2
resource vault_mount "kv" {
  path        = "secret"
  type        = "kv-v2"
}



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

resource vault_pki_secret_backend_role "admin" {
  backend = vault_mount.pki.path
  name    = "admin"
  allow_subdomains = true
  key_usage = [
    "DigitalSignature",
    "KeyAgreement",
    "KeyEncipherment",
  ]
}

## ssh-key sign
resource vault_mount "ssh" {
    type = "ssh"
    path = "ssh"
}

resource vault_ssh_secret_backend_ca "this" {
    backend = vault_mount.ssh.path
    generate_signing_key = true
}

resource vault_ssh_secret_backend_role "ubuntu" {
    name                    = "ubuntu"
    backend                 = vault_mount.ssh.path
    key_type                = "ca"
    allow_user_certificates = true
    cidr_list     = "0.0.0.0/0"
}

## Database

