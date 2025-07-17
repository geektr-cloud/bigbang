resource "alicloud_log_project" "infra" { project_name = module.startup.cred.infra_id }
