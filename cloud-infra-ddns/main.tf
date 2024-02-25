terraform {
  backend "local" { path = "../.secret/tfstates/cloud-infra-ddns/terraform.tfstate" }

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.199.0"
    }
    zipper = {
      source  = "ArthurHlt/zipper"
      version = "0.14.0"
    }
  }
}

provider "zipper" {}
resource "zipper_file" "ddns_package" {
  type        = "local"
  source      = "./ddns"
  output_path = "/tmp/${var.infra_id}-ddns-${filemd5("./ddns/index.js")}.zip"
}

resource "tls_private_key" "ddns_sign_key_pair" { algorithm = "ECDSA" }
resource "local_file" "ddns_sign_key_private" {
  content  = tls_private_key.ddns_sign_key_pair.private_key_pem
  filename = "../.secret/ddns-private.pem"
}
resource "local_file" "ddns_sign_key_public" {
  content  = tls_private_key.ddns_sign_key_pair.public_key_pem
  filename = "../.secret/ddns-public.pem"
}

resource "alicloud_fc_function" "ddns" {
  service     = var.infra_id
  name        = "ddns"
  description = "dynamic dns function"
  memory_size = "128"
  runtime     = "nodejs16"
  handler     = "index.handler"
  filename    = zipper_file.ddns_package.output_path

  environment_variables = {
    PUBLIC_KEY = tls_private_key.ddns_sign_key_pair.public_key_pem
  }
}

resource "alicloud_fc_trigger" "ddns_http" {
  service  = alicloud_fc_function.ddns.service
  function = alicloud_fc_function.ddns.name
  name     = "ddns-http"
  type     = "http"
  config = jsonencode({
    authType           = "anonymous"
    methods            = ["GET"]
    disableURLInternet = false
    authConfig         = {}
  })
}

output "get_ddns_trigger_url_on" {
  value = "https://fcnext.console.aliyun.com/${var.ali_primary_region}/services/${alicloud_fc_function.ddns.service}/function-detail/${alicloud_fc_function.ddns.name}/LATEST?tab=trigger"
}
