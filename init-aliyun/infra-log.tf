resource "random_string" "infra_id" {
  length  = 6
  upper   = false
  special = false
}

locals { infra_id = "infra-${random_string.infra_id.result}" }
resource "alicloud_log_project" "infra" { name = local.infra_id }
