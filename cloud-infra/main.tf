terraform {
  backend "local" { path = "../.secret/tfstates/cloud-infra/terraform.tfstate" }
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
  }
}

resource "random_string" "infra_id" {
  length  = 6
  upper   = false
  special = false
}

locals { infra_id = "infra-${random_string.infra_id.result}" }

resource "alicloud_resource_manager_resource_group" "infra" {
  resource_group_name = local.infra_id
  display_name        = "Infrastructure"
}

resource "local_file" "infra_variables" {
  filename = "../.secret/alicloud.infra.tfvars"
  content  = <<EOF
# ln -s ../.secret/alicloud.infra.tfvars ./alicloud.infra.auto.tfvars
infra_id     = "${local.infra_id}"
infra_fc_srv = "${alicloud_fc_service.infra_fc.name}"
EOF
}
