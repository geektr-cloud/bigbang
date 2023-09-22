resource "alicloud_log_store" "infra_fc" {
  project = alicloud_log_project.infra.name
  name    = "functions"
}

resource "alicloud_fc_service" "infra_fc" {
  name        = local.infra_id
  description = "Infrastructure functions, managed by Terraform"
  role        = alicloud_ram_role.fc_default.arn
  log_config {
    project                 = alicloud_log_project.infra.name
    logstore                = alicloud_log_store.infra_fc.name
    enable_instance_metrics = true
    enable_request_metrics  = true
  }
  depends_on = [alicloud_ram_role_policy_attachment.attach]
}

resource "local_file" "infra_variables" {
  filename = "../.secret/alicloud.infra.tfvars"
  content  = <<EOF
# ln -s ../.secret/alicloud.infra.tfvars ./alicloud.infra.auto.tfvars
infra_id = "${local.infra_id}"
infra_fc_srv = "${alicloud_fc_service.infra_fc.name}"
EOF
}
