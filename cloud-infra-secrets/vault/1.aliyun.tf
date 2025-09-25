resource "alicloud_ram_user" "terraform" {
  name         = "${local.infra.id}.terraform-admin"
  display_name = "Terrform Managed User: ${local.infra.id}.terraform-admin"
}

resource "alicloud_ram_user_policy_attachment" "terraform" {
  user_name   = alicloud_ram_user.terraform.name
  policy_name = "AdministratorAccess"
  policy_type = "System"
}

resource "alicloud_ram_access_key" "terraform" { user_name = alicloud_ram_user.terraform.name }

resource "vault_kv_secret_v2" "aliyun" {
  mount = vault_mount.terraform.path
  name  = "infra/aliyun/keys/terraform-admin"

  delete_all_versions = true

  data_json = jsonencode({
    region     = local.creds.aliyun.region
    access_key = alicloud_ram_access_key.terraform.id
    secret_key = alicloud_ram_access_key.terraform.secret
    infra      = local.aliyun
  })
}
