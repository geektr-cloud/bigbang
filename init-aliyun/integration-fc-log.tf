resource "alicloud_ram_role" "fc_default" {
  role_name = "AliyunFCDefaultRole"
  assume_role_policy_document = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = ["fc.aliyuncs.com"] }
    }]
    Version = "1"
  })
  description = "Managed by Terraform"
  force       = true
}

resource "alicloud_ram_role_policy_attachment" "attach" {
  role_name   = alicloud_ram_role.fc_default.role_name
  policy_name = "AliyunFCDefaultRolePolicy"
  policy_type = "System"
}
