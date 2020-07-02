locals {
  # Providers can't use "depends_on", so we declare them here as local variables to force the dependency.
  kv_read_users = {
    "grant":"go@hashicorp.com",
    "burkey":"burkey@hashicorp.com"
  }
  kv_write_users = {
    "burkey":"burkey@hashicorp.com"
  }
  admin_users = {
    "grant":"go@hashicorp.com",
    "burkey":"burkey@hashicorp.com"
  }
}

# User Onboarding
module "user_onboarding" {
  source = "github.com/grantorchard/terraform-vault-module-entities"

  mount_accessor = module.oidc.mount_accessor
  users = merge(local.kv_read_users,
                local.kv_write_users,
                local.admin_users
          )
}

module "group_admin" {
  source = "github.com/grantorchard/terraform-vault-module-policies"

  members = [
    for k,v in local.admin_users: lookup(module.user_onboarding.entities, k)
  ]
  policy_name = "admin"
  policy_contents = templatefile("${path.module}/policies/admin.hcl",
    {
      path = vault_mount.kv.path
    }
  )
}



module "group_kv_reader" {
  source = "github.com/grantorchard/terraform-vault-module-policies"

  members = [
    for k,v in local.kv_read_users: lookup(module.user_onboarding.entities, k)
  ]
  policy_name = "kv_reader"
  policy_contents = templatefile("${path.module}/policies/kv_read.hcl",
    {
      path = vault_mount.kv.path
    }
  )
}

module "group_kv_writer" {
  source = "github.com/grantorchard/terraform-vault-module-policies"

  members = [
    for k,v in local.kv_write_users: lookup(module.user_onboarding.entities, k)
  ]
  policy_name = "kv_writer"
  policy_contents = templatefile("${path.module}/policies/kv_write.hcl",
    {
      path = vault_mount.kv.path
    }
  )
}