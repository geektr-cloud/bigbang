resource "vault_kv_secret_v2" "infra" {
  mount               = vault_mount.terraform.path
  name                = "infra/base"
  delete_all_versions = true
  data_json           = jsonencode(local.infra)
}
