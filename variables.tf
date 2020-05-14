variable namespaces {
  type    = list
}

variable vault_url {
  type = string
}

variable deployment_name {
  default = "vault-client"
}

variable admin_username {
  default = "grant"
}

variable location {
  default = "australiaeast"
}

variable cluster_size {
  default = 1
}

variable server_size {
  default = "Standard_F2"
}