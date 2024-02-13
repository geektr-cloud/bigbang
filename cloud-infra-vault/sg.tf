resource "alicloud_security_group" "vault_public" {
  vpc_id      = local.vpc.id
  name        = "${local.infra_id}:vault-public"
  description = "Managed by Terraform"

  inner_access_policy = "Accept"
  security_group_type = "normal"
  resource_group_id   = local.infra_resource_group_id
}

resource "alicloud_security_group_rule" "vault_public_ipv4" {
  for_each = {
    ssh     = { ptc = "tcp", port = "22" }
    http    = { ptc = "tcp", port = "80" }
    https   = { ptc = "tcp", port = "443" }
    http3   = { ptc = "udp", port = "443" }
    k8s_api = { ptc = "tcp", port = "6443" }
  }

  security_group_id = alicloud_security_group.vault_public.id
  description       = each.key

  type        = "ingress"
  ip_protocol = each.value.ptc
  port_range  = "${each.value.port}/${each.value.port}"
  policy      = "accept"
  cidr_ip     = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "vault_public_ipv6" {
  for_each = alicloud_security_group_rule.vault_public_ipv4

  security_group_id = each.value.security_group_id
  description       = each.value.description

  type         = each.value.type
  ip_protocol  = each.value.ip_protocol
  port_range   = each.value.port_range
  policy       = each.value.policy
  ipv6_cidr_ip = "::/0"
}
