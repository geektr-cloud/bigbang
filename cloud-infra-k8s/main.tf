terraform {
  backend "local" { path = "../.secret/tfstates/cloud-infra-k8s/terraform.tfstate" }

  required_providers {
    tfproj = {
      source  = "anitya-tech/tfproj"
      version = "0.0.2"
    }
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
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

data "vault_kv_secret_v2" "aliyun" {
  mount = local.creds.vault.mount
  name  = "infra/aliyun/keys/terraform-admin"
}
locals { aliyun = jsondecode(nonsensitive(data.vault_kv_secret_v2.aliyun.data["infra"])) }
provider "alicloud" {
  region     = data.vault_kv_secret_v2.aliyun.data["region"]
  access_key = data.vault_kv_secret_v2.aliyun.data["access_key"]
  secret_key = data.vault_kv_secret_v2.aliyun.data["secret_key"]
}

data "alicloud_zones" "this" {
  available_instance_type = "ecs.t6-c1m4.xlarge"
  available_disk_category = "cloud_efficiency"
}

resource "random_shuffle" "zone" {
  input = data.alicloud_zones.this.ids
  lifecycle { ignore_changes = [input] }
}
locals {
  zone_id = random_shuffle.zone.result[0]
  vswitch = local.aliyun.vswitches[local.zone_id]
}


data "vault_kv_secret_v2" "cloudflare" {
  mount = local.creds.vault.mount
  name  = "infra/cloudflare/tokens/terraform-admin"
}
provider "cloudflare" { api_token = data.vault_kv_secret_v2.cloudflare.data["api_token"] }
locals { cloudflare = jsondecode(nonsensitive(data.vault_kv_secret_v2.cloudflare.data["infra"])) }
