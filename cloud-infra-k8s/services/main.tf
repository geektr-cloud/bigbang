terraform {
  backend "local" { path = "../../.secret/tfstates/cloud-infra-k8s/services/terraform.tfstate" }

  required_providers {
    tfproj = {
      source  = "anitya-tech/tfproj"
      version = "0.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3"
    }
  }
}

locals {
  creds = {
    vault = yamldecode(file(provider::tfproj::ensure("{secret.path}/creds/vault.yaml")))
  }
}

provider "vault" {
  address = local.creds.vault.address
  auth_login {
    path = local.creds.vault.auth_login_path
    parameters = {
      role_id   = local.creds.vault.role_id
      secret_id = local.creds.vault.secret_id
    }
  }
}

data "vault_kv_secret_v2" "infra" {
  mount = local.creds.vault.mount
  name  = "infra/base"
}
locals { infra = nonsensitive(data.vault_kv_secret_v2.infra.data) }

data "vault_kv_secret_v2" "cloudflare" {
  mount = local.creds.vault.mount
  name  = "infra/cloudflare/tokens/terraform-admin"
}
provider "cloudflare" { api_token = data.vault_kv_secret_v2.cloudflare.data["api_token"] }
locals { cloudflare = jsondecode(nonsensitive(data.vault_kv_secret_v2.cloudflare.data["infra"])) }

data "vault_kv_secret_v2" "kubernetes" {
  mount = local.creds.vault.mount
  name  = "infra/k8s-pokemon/tokens/terraform-admin"
}

provider "kubernetes" {
  host                   = data.vault_kv_secret_v2.kubernetes.data["public_host"]
  cluster_ca_certificate = data.vault_kv_secret_v2.kubernetes.data["cluster_ca_certificate"]
  token                  = data.vault_kv_secret_v2.kubernetes.data["token"]
}
locals { k8s = jsondecode(nonsensitive(data.vault_kv_secret_v2.kubernetes.data["infra"])) }

resource "kubernetes_namespace" "this" {
  metadata { name = "infra-services" }
}
