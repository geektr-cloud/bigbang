data "cloudflare_api_token_permission_groups" "all" {}
resource "cloudflare_api_token" "caddy_acme" {
  name = "closet-caddy-acme"
  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Read"],
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = { "com.cloudflare.api.account.zone.${local.cf_zone}" = "*" }
  }
}

resource "cloudflare_record" "closet" {
  zone_id = local.cf_zone
  name    = local.closet.hostname
  type    = "A"
  content = alicloud_eip_address.closet.ip_address
  ttl     = 1
  proxied = false
}

resource "cloudflare_record" "services" {
  for_each = toset(["vault", "bitwarden", "certimate", "auth"])

  zone_id = local.cf_zone
  name    = each.value
  type    = "CNAME"
  content = "closet.${local.infra.base_domain}"
  ttl     = 1
  proxied = false
}
