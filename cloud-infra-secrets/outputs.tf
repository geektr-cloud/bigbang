resource "local_sensitive_file" "keycloak" {
  filename = provider::tfproj::format("{secret.path}/creds/keycloak.yaml")
  content = yamlencode({
    url      = "https://auth.${local.infra.base_domain}"
    username = "root"
    password = random_password.keycloak_admin_password.result
  })
}

resource "local_sensitive_file" "vault" {
  filename = provider::tfproj::format("{secret.path}/creds/vault-addr.yaml")
  content = yamlencode({
    address = "https://vault.${local.infra.base_domain}"
    token   = ""
  })
}
