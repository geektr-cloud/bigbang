terraform {
  backend "local" { path = "../.secret/tfstates/init-aliyun/terraform.tfstate" }
}

locals {
  ali_region = "cn-shanghai"
}
