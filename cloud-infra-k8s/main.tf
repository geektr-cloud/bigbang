terraform {
  backend "local" { path = "../.secret/tfstates/cloud-infra-k8s/terraform.tfstate" }

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3"
    }
  }
}

module "vault" {
  source   = "/home/geektr/projects/github.com/geektheripper/terraform-helpers/providers/vault/approle-file"
  filename = "${path.module}/../.secret/vault-approle-terraform.json"
}

provider "vault" {
  address = module.vault.address
  auth_login {
    path = module.vault.auth_login_path
    parameters = {
      role_id   = module.vault.role_id
      secret_id = module.vault.secret_id
    }
  }
}

module "alicloud" {
  source = "/home/geektr/projects/github.com/geektheripper/terraform-helpers/providers/alicloud/vault"

  vault_mount = module.vault.mount
  vault_key   = "infra/alicloud-geektr/keys/terraform-admin"
}

provider "alicloud" {
  region     = module.alicloud.region
  access_key = module.alicloud.access_key
  secret_key = module.alicloud.secret_key
}

data "alicloud_zones" "this" {
  available_instance_type = "ecs.t5-c1m2.xlarge"
  available_disk_category = "cloud_efficiency"
}

resource "random_shuffle" "zone" { input = data.alicloud_zones.this.ids }

locals {
  infra_id          = module.alicloud.extra.infra_id
  vpc               = module.alicloud.extra.vpc
  zone              = [for i in data.alicloud_zones.this.zones : i if i.id == random_shuffle.zone.result[0]][0]
  vswitch           = module.alicloud.extra.vswitches[local.zone.id]
  resource_group_id = module.alicloud.extra.resource_group_id
}
