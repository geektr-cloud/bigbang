variable "superuser" {
  type = object({
    name  = optional(string, "superuser")
    email = optional(string, null)
    attributes = optional(map(string), {
      nickname = "👑 超级管理员"
    })
  })
  default = {}
}

resource "random_password" "superuser" {
  length  = 48
  special = false

  lifecycle {
    ignore_changes = [special]
  }
}

resource "keycloak_user" "superuser" {
  depends_on = [keycloak_realm_user_profile.this]

  realm_id       = keycloak_realm.this.id
  username       = var.superuser.name
  email          = var.superuser.email == null ? "superuser@${var.domain}" : var.superuser.email
  enabled        = true
  email_verified = true

  first_name = "@${var.domain}"
  last_name  = "超级管理员"

  attributes = var.superuser.attributes

  initial_password {
    value     = random_password.superuser.result
    temporary = false
  }
}

data "keycloak_openid_client" "realm_management" {
  realm_id  = keycloak_realm.this.id
  client_id = "realm-management"
}

data "keycloak_role" "realm_management" {
  realm_id  = keycloak_realm.this.id
  client_id = data.keycloak_openid_client.realm_management.id
  name      = "realm-admin"
}

resource "keycloak_user_roles" "superuser_realm_management" {
  realm_id = keycloak_realm.this.id
  user_id  = keycloak_user.superuser.id

  role_ids = [
    data.keycloak_role.realm_management.id
  ]
}

output "superuser" {
  value = {
    username = keycloak_user.superuser.username
    email    = keycloak_user.superuser.email
    password = random_password.superuser.result
  }
}
