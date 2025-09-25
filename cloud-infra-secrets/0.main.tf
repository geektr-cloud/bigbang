terraform {
  backend "local" { path = "../.secret/states/cloud-infra-secrets/terraform.tfstate" }

  required_providers {
    tfproj = {
      source  = "anitya-tech/tfproj"
      version = "0.0.2"
    }
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

locals {
  creds = {
    aliyun     = yamldecode(file(provider::tfproj::ensure("{secret.path}/creds/aliyun.yaml")))
    cloudflare = yamldecode(file(provider::tfproj::ensure("{secret.path}/creds/cloudflare.yaml")))
  }
  infra  = yamldecode(file(provider::tfproj::ensure("{secret.path}/public/infra.yaml")))
  aliyun = yamldecode(file(provider::tfproj::ensure("{secret.path}/public/infra-aliyun.yaml")))
}

provider "alicloud" {
  access_key = local.creds.aliyun.access_key
  secret_key = local.creds.aliyun.secret_key
  region     = local.creds.aliyun.region
}

data "alicloud_zones" "zones" {
  available_instance_type = "ecs.t6-c1m1.large"
  available_disk_category = "cloud_efficiency"
}

resource "random_shuffle" "zone" { input = data.alicloud_zones.zones.ids }

locals {
  zone    = [for i in data.alicloud_zones.zones.zones : i if i.id == random_shuffle.zone.result[0]][0]
  vswitch = local.aliyun.vswitches[local.zone.id]
}

provider "cloudflare" {
  email   = local.creds.cloudflare.email
  api_key = local.creds.cloudflare.api_key
}

data "cloudflare_zones" "this" {
  filter { name = local.infra.base_domain }
}

locals {
  cf_zone = data.cloudflare_zones.this.zones[0].id

  closet_fqdn = "closet.${local.infra.base_domain}"
}
