terraform {
  backend "local" { path = "../../.secret/tfstates/cloud-infra-k8s/kubernetes/terraform.tfstate" }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
    kubectl = {
      source  = "alekc/kubectl"
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
  source   = "github.com/geektheripper/terraform-helpers//providers/vault/approle-file"
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
  source = "github.com/geektheripper/terraform-helpers//providers/alicloud/vault"

  vault_mount = module.vault.mount
  vault_key   = "infra/alicloud-geektr/keys/terraform-admin"
}

provider "alicloud" {
  region     = module.alicloud.region
  access_key = module.alicloud.access_key
  secret_key = module.alicloud.secret_key
}

data "vault_kv_secret_v2" "this" {
  mount = module.vault.mount
  name  = "manual/kubernetes-pokemon"
}

provider "kubernetes" {
  host                   = data.vault_kv_secret_v2.this.data["host"]
  client_certificate     = data.vault_kv_secret_v2.this.data["client_certificate"]
  client_key             = data.vault_kv_secret_v2.this.data["client_key"]
  cluster_ca_certificate = data.vault_kv_secret_v2.this.data["cluster_ca_certificate"]
}

provider "kubectl" {
  host                   = data.vault_kv_secret_v2.this.data["host"]
  client_certificate     = data.vault_kv_secret_v2.this.data["client_certificate"]
  client_key             = data.vault_kv_secret_v2.this.data["client_key"]
  cluster_ca_certificate = data.vault_kv_secret_v2.this.data["cluster_ca_certificate"]

  load_config_file = false
}
