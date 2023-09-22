resource "alicloud_ram_role" "fc_default" {
  name        = "AliyunFCDefaultRole"
  document    = <<EOF
{
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Effect": "Allow",
    "Principal": {"Service": ["fc.aliyuncs.com"]}
  }],
  "Version": "1"
}
EOF
  description = "Managed by Terraform"
  force       = true
}

resource "alicloud_ram_role_policy_attachment" "attach" {
  role_name   = alicloud_ram_role.fc_default.name
  policy_name = "AliyunFCDefaultRolePolicy"
  policy_type = "System"
}
