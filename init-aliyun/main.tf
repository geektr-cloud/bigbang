terraform {
  backend "local" { path = "../.secret/tfstates/init-aliyun/terraform.tfstate" }
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.199.0"
    }
  }
}
