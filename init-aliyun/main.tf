terraform {
  backend "local" { path = "../.secret/tfstates/init-aliyun/terraform.tfstate" }
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
  }
}

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
