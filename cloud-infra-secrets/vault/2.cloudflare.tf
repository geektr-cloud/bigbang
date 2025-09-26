data "cloudflare_api_token_permission_groups" "all" {}

data "cloudflare_user" "this" {}
data "cloudflare_zones" "this" {
  filter { name = local.infra.base_domain }
}

resource "cloudflare_api_token" "terraform" {
  name = "${local.infra.id}.terraform-token-admin"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.user["API Tokens Write"]
    ]
    resources = { "com.cloudflare.api.user.${data.cloudflare_user.this.id}" = "*" }
  }

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Read"],
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = { "com.cloudflare.api.account.zone.${data.cloudflare_zones.this.zones[0].id}" = "*" }
  }
}

resource "vault_kv_secret_v2" "cloudflare" {
  mount = vault_mount.terraform.path
  name  = "infra/cloudflare/tokens/terraform-admin"

  delete_all_versions = true

  data_json = jsonencode({
    email      = local.creds.cloudflare.email
    account_id = local.creds.cloudflare.account_id
    api_token  = cloudflare_api_token.terraform.value
    infra = {
      base_domain_zone = data.cloudflare_zones.this.zones[0]
    }
  })
}
