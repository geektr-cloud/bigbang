terraform {
  backend "local" { path = "../../.secret/states/cloud-infra-secrets/vault/terraform.tfstate" }

  required_providers {
    tfproj = {
      source  = "anitya-tech/tfproj"
      version = "0.0.2"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3"
    }
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

locals {
  creds = {
    aliyun     = yamldecode(file(provider::tfproj::ensure("{secret.path}/public/aliyun.yaml")))
    cloudflare = yamldecode(file(provider::tfproj::ensure("{secret.path}/public/cloudflare.yaml")))
  }
  infra = yamldecode(file(provider::tfproj::ensure("{secret.path}/public/infra-v2.yaml")))
}

provider "alicloud" {
  access_key = local.creds.aliyun.access_key
  secret_key = local.creds.aliyun.secret_key
  region     = local.creds.aliyun.region
}

provider "cloudflare" {
  email   = local.creds.cloudflare.email
  api_key = local.creds.cloudflare.api_key
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
