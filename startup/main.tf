terraform {
  backend "local" { path = "../.secret/states/startup/terraform.tfstate" }
  required_providers {
    tfproj = {
      source  = "anitya-tech/tfproj"
      version = "0.0.2"
    }
  }
}

resource "random_string" "infra_id" {
  length  = 6
  upper   = false
  special = false
}
locals { infra_id = "infra-${random_string.infra_id.result}" }

variable "base_domain" { type = string }
resource "local_file" "infra" {
  filename = provider::tfproj::format("{secret.path}/public/infra.yaml")
  content = yamlencode({
    id          = local.infra_id,
    base_domain = var.base_domain,
  })
}

locals {
  ensure_creds = [
    provider::tfproj::ensure("{secret.path}/creds/cloudflare.yaml"),
    # email:
    # api_key:

    provider::tfproj::ensure("{secret.path}/creds/aliyun.yaml"),
    # region:
    # access_key:
    # secret_key:
  ]
}
