resource "alicloud_ram_user" "cert_manager" {
  name         = "${var.infra_id}.cert-manager"
  display_name = "Terrafrom Cert Manager"
}

resource "alicloud_ram_user_policy_attachment" "cert_manager_AliyunDomainFullAccess" {
  user_name   = alicloud_ram_user.cert_manager.name
  policy_name = "AliyunDNSFullAccess"
  policy_type = "System"
}

resource "alicloud_ram_access_key" "cert_manager" {
  user_name = alicloud_ram_user.cert_manager.name
}
