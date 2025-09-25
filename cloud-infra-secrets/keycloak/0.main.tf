terraform {
  backend "local" { path = "../../.secret/states/cloud-infra-secrets/keycloak/terraform.tfstate" }

  required_providers {
    tfproj = {
      source  = "anitya-tech/tfproj"
      version = "0.0.2"
    }
    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.0"
    }
  }
}

locals {
  creds = {
    keycloak = yamldecode(file(provider::tfproj::ensure("{secret.path}/creds/keycloak.yaml")))
  }
  infra = yamldecode(file(provider::tfproj::ensure("{secret.path}/public/infra-v2.yaml")))
}

provider "keycloak" {
  url       = local.creds.keycloak.url
  client_id = "admin-cli"
  username  = local.creds.keycloak.username
  password  = local.creds.keycloak.password
}

module "keycloak" {
  source = "./realm"

  keycloak_url   = local.creds.keycloak.url
  inner_endpoint = "http://keycloak:8080"

  domain             = "geektr.co"
  realm_display_name = "GeekTR Cloud"

  superuser = {
    name       = "superuser"
    email      = "superuser@geektr.co"
    attributes = { nickname = "👑 超级管理员" }
  }
}

resource "local_sensitive_file" "keycloak" {
  filename = provider::tfproj::format("{secret.path}/creds/keycloak-realm.yaml")
  content = yamlencode({
    url      = local.creds.keycloak.url
    realm    = module.keycloak.realm.name
    username = module.keycloak.superuser.username
    password = module.keycloak.superuser.password

    realm = module.keycloak.realm
  })
}
