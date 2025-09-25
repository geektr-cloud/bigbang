terraform {
  backend "local" { path = "../.secret/states/init-aliyun/terraform.tfstate" }
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

provider "alicloud" {
  access_key = provider::tfproj::query("{secret.path}/creds/aliyun.yaml", "access_key")
  secret_key = provider::tfproj::query("{secret.path}/creds/aliyun.yaml", "secret_key")
  region     = provider::tfproj::query("{secret.path}/creds/aliyun.yaml", "region")
}

data "alicloud_account" "this" {}
