# RAM
resource "alicloud_ram_policy" "infra_fc" {
  policy_name     = "InfraFCRolePolicy-${local.infra_id}"
  policy_document = <<EOF
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "alidns:UpdateDomainRecord",
        "alidns:UpdateDomainRecordRemark",
        "alidns:AddDomainRecord",
        "alidns:DeleteDomainRecord",
        "alidns:DescribeDomainRecordInfo",
        "alidns:DescribeDomainRecords",
        "alidns:DescribeSubDomainRecords",
        "alidns:DeleteSubDomainRecords",
        "alidns:SetDomainRecordStatus",
        "alidns:RefreshDomainRecord"
      ],
      "Resource": [
        "acs:alidns:*:${data.alicloud_account.this.id}:domain/${var.base_domain}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["log:PostLogStoreLogs"],
      "Resource": [
        "acs:log:*:${data.alicloud_account.this.id}:project/${alicloud_log_project.infra.project_name}/logstore/*"
      ]
    }
  ]
}
EOF
  description     = "Managed by Terraform"
  rotate_strategy = "DeleteOldestNonDefaultVersionWhenLimitExceeded"
  force           = true
}

resource "alicloud_ram_role" "infra_fc" {
  name        = "AliyunFCRole-${local.infra_id}"
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

resource "alicloud_ram_role_policy_attachment" "infra_fc" {
  role_name   = alicloud_ram_role.infra_fc.name
  policy_name = alicloud_ram_policy.infra_fc.policy_name
  policy_type = alicloud_ram_policy.infra_fc.type
}


# Log
resource "alicloud_log_store" "infra_fc" {
  project_name  = alicloud_log_project.infra.project_name
  logstore_name = "functions"
}

# FC
resource "alicloud_fc_service" "infra_fc" {
  name        = local.infra_id
  description = "Infrastructure functions, managed by Terraform"
  role        = alicloud_ram_role.infra_fc.arn
  log_config {
    project                 = alicloud_log_project.infra.project_name
    logstore                = alicloud_log_store.infra_fc.logstore_name
    enable_instance_metrics = true
    enable_request_metrics  = true
  }
  depends_on = [alicloud_ram_role_policy_attachment.infra_fc]
}

