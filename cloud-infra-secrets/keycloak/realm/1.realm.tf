variable "keycloak_url" { type = string }
variable "inner_endpoint" {
  type    = string
  default = null
}

variable "domain" { type = string }

variable "realm_display_name" { type = string }
variable "realm_password_policy" {
  type    = string
  default = "upperCase(1) and length(12) and notUsername(undefined)"
}
variable "realm_attributes" {
  type    = list(any)
  default = []
}

variable "attributes_set" {
  type    = list(any)
  default = []
}

variable "smtp_server" {
  type = object({
    host     = string
    port     = optional(string, "25")
    starttls = optional(bool, false)
    ssl      = optional(bool, false)

    auth = optional(object({
      username = string
      password = string
    }), null)

    from              = string
    from_display_name = optional(string, null)
  })
  default = null
}

resource "keycloak_realm" "this" {
  realm             = var.domain
  enabled           = true
  display_name      = var.realm_display_name
  display_name_html = "<b>${var.realm_display_name}</b>"

  login_theme = "keycloak.v2"

  access_code_lifespan = "1h"

  ssl_required    = "external"
  password_policy = var.realm_password_policy

  dynamic "smtp_server" {
    for_each = var.smtp_server != null ? [var.smtp_server] : []
    content {
      host              = smtp_server.value.host
      port              = smtp_server.value.port
      starttls          = smtp_server.value.starttls
      ssl               = smtp_server.value.ssl
      from              = smtp_server.value.from
      from_display_name = smtp_server.value.from_display_name

      auth {
        username = smtp_server.value.auth.username
        password = smtp_server.value.auth.password
      }
    }
  }

  internationalization {
    default_locale    = "zh-CN"
    supported_locales = sort(["zh-CN"])
  }
}

# locals {
#   default_attributes      = jsondecode(file("${path.module}/profile.json")).attributes
#   default_attributes_map  = { for a in local.default_attributes : a.name => a }
#   addition_attributes_map = { for a in var.realm_attributes : a.name => a }
#   merged_attributes_map   = merge(local.default_attributes_map, local.addition_attributes_map)
#   merged_attributes       = [for _, v in local.merged_attributes_map : v]
# }

resource "keycloak_realm_user_profile" "this" {
  realm_id = keycloak_realm.this.id

  unmanaged_attribute_policy = "ENABLED"

  dynamic "attribute" {
    for_each = [for _, v in merge(
      { for attr in jsondecode(file("${path.module}/profile.json")).attributes : attr.name => attr },
      { for attr in var.realm_attributes : attr.name => attr },
      [for setname in var.attributes_set : {
        for attr in jsondecode(file("${path.module}/profile.${setname}.json")).attributes : attr.name => attr
      }]...
    ) : v]
    content {
      name         = attribute.value.name
      display_name = attribute.value.displayName

      multi_valued = attribute.value.multivalued

      permissions {
        view = attribute.value.permissions.view
        edit = attribute.value.permissions.edit
      }

      dynamic "validator" {
        for_each = attribute.value.validations
        content {
          name   = validator.key
          config = validator.value
        }
      }
    }
  }
}

locals {
  issuer     = nonsensitive("${var.keycloak_url}/realms/${keycloak_realm.this.realm}")
  logout_url = nonsensitive("${local.issuer}/protocol/openid-connect/logout")
}

output "realm" { value = {
  id           = keycloak_realm.this.id
  name         = keycloak_realm.this.realm
  display_name = keycloak_realm.this.display_name

  issuer     = local.issuer
  logout_url = local.logout_url

  inner_endpoint = var.inner_endpoint
} }
