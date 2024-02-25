terraform {
  backend "local" { path = "../../.secret/tfstates/cloud-infra-vault/kubernetes/terraform.tfstate" }

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2"
    }
  }
}

provider "kubernetes" { config_path = "${path.module}/../../.secret/cloud-infra-vault.k8s.yml" }
provider "kubectl" { config_path = "${path.module}/../../.secret/cloud-infra-vault.k8s.yml" }

resource "kubernetes_namespace" "this" {
  metadata { name = "vault" }
}
