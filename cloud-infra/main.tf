terraform {
  backend "local" { path = "../.secret/tfstates/cloud-infra/terraform.tfstate" }
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
  }
}

module "this" { source = "github.com/linolabx/tfmodules?ref=module-info@v0.0.1" }
module "startup" {
  source     = "github.com/linolabx/tfmodules?ref=module-info@v0.0.1"
  module_rel = "startup"
}
provider "alicloud" {
  access_key = module.startup.cred.aliyun.access_key
  secret_key = module.startup.cred.aliyun.secret_key
  region     = module.startup.cred.aliyun.region
}
data "alicloud_account" "this" {}

resource "alicloud_resource_manager_resource_group" "infra" {
  resource_group_name = module.startup.cred.infra_id
  display_name        = "Infrastructure"
}

resource "local_file" "output" {
  filename = module.this.outputs_file
  content = yamlencode({
    infra_id = module.startup.cred.infra_id

    fc_service = alicloud_fc_service.infra_fc

    vpc            = alicloud_vpc.infra
    vswitches      = alicloud_vswitch.infra
    resource_group = alicloud_resource_manager_resource_group.infra
  })
}
