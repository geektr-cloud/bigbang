terraform {
  backend "local" { path = "../.secret/tfstates/cloud-infra-vault/terraform.tfstate" }

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
  }
}

data "terraform_remote_state" "cloud_infra" {
  backend = "local"
  config  = { path = "../.secret/tfstates/cloud-infra/terraform.tfstate" }
}

data "alicloud_zones" "zones" {
  available_instance_type = "ecs.t6-c1m1.large"
  available_disk_category = "cloud_efficiency"
}

resource "random_shuffle" "zone" { input = data.alicloud_zones.zones.ids }

locals {
  infra_id                = var.infra_id
  vpc                     = data.terraform_remote_state.cloud_infra.outputs.infra_vpc
  zone                    = [for i in data.alicloud_zones.zones.zones : i if i.id == random_shuffle.zone.result[0]][0]
  vswitch                 = data.terraform_remote_state.cloud_infra.outputs.infra_vpc_vswitches[local.zone.id]
  infra_resource_group_id = data.terraform_remote_state.cloud_infra.outputs.infra_resource_group_id
}
