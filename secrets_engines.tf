#  Secrets Engines
## kv-v2
resource vault_mount "kv" {
  path        = "secret"
  type        = "kv-v2"
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
    allowed_users           = "*"
    default_extensions      = {
        "permit-pty" = ""
    }
    default_user            = "ubuntu"
    ttl                     = "1800"
}