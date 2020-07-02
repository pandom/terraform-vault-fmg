resource vault_mount "postgres" {
  type = "database"
  path = "postgres"
}

resource vault_database_secret_backend_connection "postgres" {
  backend       = vault_mount.postgres.path
  name          = "postgres"
  allowed_roles = ["read", "write"]

  postgresql {
    connection_url = "postgres://root:rootpassword@${azurerm_linux_virtual_machine.this[0].private_ip_address}:5432/postgres"
  }
}

resource vault_database_secret_backend_role "read" {
  backend             = vault_mount.postgres.path
  name                = "my-role"
  db_name             = vault_database_secret_backend_connection.postgres.name
  creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"]
}