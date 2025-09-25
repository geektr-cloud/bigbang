resource "alicloud_security_group" "closet_public" {
  vpc_id              = local.aliyun.vpc.id
  security_group_name = "${local.infra.id}:closet-public"
  description         = "Managed by Terraform"

  inner_access_policy = "Accept"
  security_group_type = "normal"
  resource_group_id   = local.aliyun.resource_group.id
}

resource "alicloud_security_group_rule" "closet_public_ipv4" {
  for_each = {
    ssh   = { ptc = "tcp", port = "22" }
    http  = { ptc = "tcp", port = "80" }
    https = { ptc = "tcp", port = "443" }
    http3 = { ptc = "udp", port = "443" }
  }

  security_group_id = alicloud_security_group.closet_public.id
  description       = each.key

  type        = "ingress"
  ip_protocol = each.value.ptc
  port_range  = "${each.value.port}/${each.value.port}"
  policy      = "accept"
  cidr_ip     = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "closet_public_ipv6" {
  for_each = alicloud_security_group_rule.closet_public_ipv4

  security_group_id = each.value.security_group_id
  description       = each.value.description

  type         = each.value.type
  ip_protocol  = each.value.ip_protocol
  port_range   = each.value.port_range
  policy       = each.value.policy
  ipv6_cidr_ip = "::/0"
}
