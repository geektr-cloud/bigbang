terraform {
  backend "local" { path = "../.secret/states/cloud-infra/terraform.tfstate" }
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
    tfproj = {
      source  = "anitya-tech/tfproj"
      version = "0.0.2"
    }
  }
}

locals {
  creds = {
    aliyun = yamldecode(file(provider::tfproj::ensure("{secret.path}/public/aliyun.yaml")))
  }
  infra = yamldecode(file(provider::tfproj::ensure("{secret.path}/public/infra.yaml")))
}

provider "alicloud" {
  access_key = local.creds.aliyun.access_key
  secret_key = local.creds.aliyun.secret_key
  region     = local.creds.aliyun.region
}
data "alicloud_account" "this" {}

resource "alicloud_resource_manager_resource_group" "infra" {
  resource_group_name = local.infra.id
  display_name        = "Infrastructure"
}

resource "local_file" "output" {
  filename = provider::tfproj::format("{secret.path}/public/infra-v2.yaml")
  content = yamlencode(merge(local.infra, {
    aliyun = {
      vpc            = alicloud_vpc.infra
      vswitches      = alicloud_vswitch.infra
      resource_group = alicloud_resource_manager_resource_group.infra
    }
  }))
}
