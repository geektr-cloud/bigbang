terraform {
  backend "local" { path = "../../.secret/tfstates/cloud-infra-k8s/services/terraform.tfstate" }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
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

module "vault" {
  source   = "/home/geektr/projects/github.com/geektheripper/terraform-helpers/providers/vault/approle-file"
  filename = "${path.module}/../../.secret/vault-approle-terraform.json"
}

provider "vault" {
  address = module.vault.address
  auth_login {
    path = module.vault.auth_login_path
    parameters = {
      role_id   = module.vault.role_id
      secret_id = module.vault.secret_id
    }
  }
}

module "alicloud" {
  source = "/home/geektr/projects/github.com/geektheripper/terraform-helpers/providers/alicloud/vault"

  vault_mount = module.vault.mount
  vault_key   = "infra/alicloud-geektr/keys/terraform-admin"
}

provider "alicloud" {
  region     = module.alicloud.region
  access_key = module.alicloud.access_key
  secret_key = module.alicloud.secret_key
}

module "kubernetes" {
  source = "/home/geektr/projects/github.com/geektheripper/terraform-helpers/providers/terraform/vault-sa"

  vault_mount = module.vault.mount
  vault_key   = "infra/kubernetes-pokemon/tokens/terraform-admin"
}

provider "kubernetes" {
  host                   = module.kubernetes.host
  cluster_ca_certificate = module.kubernetes.cluster_ca_certificate
  token                  = module.kubernetes.token
}

resource "kubernetes_namespace" "this" {
  metadata { name = "infra-services" }
}
