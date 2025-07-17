terraform {
  backend "local" { path = "../.secret/tfstates/startup/terraform.tfstate" }
}

module "startup" { source = "github.com/linolabx/tfmodules?ref=module-info@v0.0.1" }

variable "ali_key" {
  type        = string
  description = "Aliyun Access Key with Administrator Privileges"
}
variable "ali_secret" {
  type        = string
  sensitive   = true
  description = "Aliyun Secret Key with Administrator Privileges"
}

variable "ali_region" {
  type        = string
  description = "Aliyun Region"
}

resource "random_string" "infra_id" {
  length  = 6
  upper   = false
  special = false
}
locals { infra_id = "infra-${random_string.infra_id.result}" }

variable "base_domain" {
  type        = string
  description = "Base Domain for the Infrastructure"
}

resource "local_file" "cred" {
  filename = "${module.startup.secrets_dir}/cred.yaml"
  content = yamlencode({
    infra_id = local.infra_id

    aliyun = {
      access_key = var.ali_key
      secret_key = var.ali_secret
      region     = var.ali_region
    }

    base_domain = var.base_domain
  })
}
