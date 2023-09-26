terraform {
  backend "local" { path = "../.secret/tfstates/cloud-infra/terraform.tfstate" }
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.199.0"
    }
  }
}
