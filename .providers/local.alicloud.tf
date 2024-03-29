# ln -s ../.secret/alicloud.tfvars ./alicloud.auto.tfvars
# ln -s ../.providers/local.alicloud.tf ./prov.alicloud.tf

#   alicloud = {
#     source  = "aliyun/alicloud"
#     version = "~> 1"
#   }

variable "ali_key" { type = string }
variable "ali_secret" { type = string }
variable "ali_primary_region" {
  type    = string
  default = "cn-shanghai"
}

provider "alicloud" {
  access_key = var.ali_key
  secret_key = var.ali_secret
  region     = var.ali_primary_region
}

data "alicloud_account" "this" {}

variable "infra_id" { type = string }
