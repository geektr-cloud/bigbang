resource "vault_mount" "terraform" {
  path        = "terraform-kv"
  type        = "kv"
  options     = { version = "2" }
  description = "kv secret for terraform"
}

resource "vault_auth_backend" "terraform_role" {
  type = "approle"
  path = "terraform-role"

  tune {
    default_lease_ttl  = "1h"
    listing_visibility = "hidden"
    token_type         = "service"
  }
}

resource "vault_policy" "terraform" {
  name   = "terraform/terraform"
  policy = <<-EOF
  path "auth/token/create" { capabilities = ["create", "read", "update", "list"] }

  path "${vault_mount.terraform.path}/data/manual/*" { capabilities = ["read"] }

  path "${vault_mount.terraform.path}/data/infra/*" { capabilities = ["create", "read", "update", "patch", "delete", "list"] }
  path "${vault_mount.terraform.path}/metadata/infra/*" { capabilities = ["create", "read", "update", "patch", "delete", "list"] }
  EOF
}

resource "vault_approle_auth_backend_role" "terraform" {
  backend        = vault_auth_backend.terraform_role.path
  role_name      = "terraform"
  role_id        = "terraform"
  token_policies = [vault_policy.terraform.id]

  token_explicit_max_ttl = 3600
}

resource "vault_approle_auth_backend_role_secret_id" "terraform" {
  backend   = vault_auth_backend.terraform_role.path
  role_name = vault_approle_auth_backend_role.terraform.role_name
}

resource "local_sensitive_file" "vault_creds" {
  filename        = provider::tfproj::format("{secret.path}/creds/vault.yaml")
  file_permission = "0600"
  content = yamlencode({
    address         = local.creds.vault.address
    backend         = vault_auth_backend.terraform_role.path
    auth_login_path = "auth/${vault_auth_backend.terraform_role.path}/login"
    role_id         = vault_approle_auth_backend_role.terraform.role_id
    secret_id       = vault_approle_auth_backend_role_secret_id.terraform.secret_id
    mount           = vault_mount.terraform.path
  })
}
