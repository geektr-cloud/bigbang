terraform {
  backend "local" { path = "../../.secret/tfstates/cloud-infra-vault/vault/terraform.tfstate" }

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3"
    }
  }
}

variable "vault_addr" {
  type    = string
  default = "https://vault.geektr.co"
}
variable "vault_token" {
  type      = string
  sensitive = true
}

provider "vault" {
  address = var.vault_addr
  token   = var.vault_token
}
