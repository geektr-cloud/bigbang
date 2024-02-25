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

module "terraform_role" {
  source = "/home/geektr/projects/github.com/geektheripper/terraform-helpers/providers/vault/approle-file/new"

  filename = "${path.module}/../../.secret/vault-approle-terraform.json"

  vault_addr    = var.vault_addr
  vault_backend = vault_auth_backend.terraform_role.path
  vault_role_id = "terraform"
  vault_mount   = vault_mount.terraform.path

  policy_document = <<EOF
path "auth/token/create" { capabilities = ["create", "read", "update", "list"] }

path "${vault_mount.terraform.path}/data/manual/*" { capabilities = ["read"] }

path "${vault_mount.terraform.path}/data/infra/*" { capabilities = ["create", "read", "update", "patch", "delete", "list"] }
path "${vault_mount.terraform.path}/metadata/infra/*" { capabilities = ["create", "read", "update", "patch", "delete", "list"] }
EOF
}
