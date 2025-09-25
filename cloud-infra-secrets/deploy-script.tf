resource "random_password" "vaultwarden_admin_token" {
  length  = 48
  special = false
}
resource "random_password" "vaultwarden_postgres_userpass" {
  length  = 24
  special = false
}
resource "random_password" "keycloak_admin_password" {
  length  = 48
  special = false
}
resource "random_password" "keycloak_postgres_userpass" {
  length  = 24
  special = false
}


locals { v2ray = yamldecode(file(provider::tfproj::ensure("{secret.path}/public/v2ray.yaml"))) }

resource "local_sensitive_file" "secrets_env" {
  filename = provider::tfproj::format("{module.store}/secrets.env")
  content  = <<-EOF
  CADDY_CF_API_TOKEN=${cloudflare_api_token.caddy_acme.value}

  VAULTWARDEN_POSTGRES_PASSWORD=${random_password.vaultwarden_postgres_userpass.result}
  VAULTWARDEN_ADMIN_TOKEN=${random_password.vaultwarden_admin_token.result}

  KEYCLOAK_ADMIN_PASSWORD=${random_password.keycloak_admin_password.result}
  KEYCLOAK_POSTGRES_PASSWORD=${random_password.keycloak_postgres_userpass.result}

  V2RAY_SERVER_ADDR=${local.v2ray.server.address}
  V2RAY_SERVER_PORT=${local.v2ray.server.port}
  V2RAY_SERVER_UUID=${local.v2ray.server.uuid}
  EOF
}

locals { ssh_config = provider::tfproj::format("{module.store}/ssh_config") }
resource "local_file" "ssh_config" {
  filename = local.ssh_config
  content  = <<-EOF
  Host *
    User terraform
    IdentityFile ${provider::tfproj::ensure("{secret.path}/terraform")}
  EOF
}

resource "local_file" "deploy_script" {
  filename             = "${path.module}/deploy.sh"
  directory_permission = "0700"
  file_permission      = "0700"
  content              = <<-EOF
  #!/usr/bin/env bash

  tfssh() { ssh -F ${local.ssh_config} "$@"; }
  tfsync() { rsync -avz -e 'ssh -F ${local.ssh_config}' "$@"; }

  tfsync --delete compose/ ${local.closet_fqdn}:/srv/closet
  tfsync ${local_sensitive_file.secrets_env.filename} ${local.closet_fqdn}:/srv/closet/secrets.env

  tfssh ${local.closet_fqdn} "cd /srv/closet && docker compose --env-file secrets.env up -d"
  EOF
}
