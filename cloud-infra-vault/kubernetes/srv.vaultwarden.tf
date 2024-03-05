module "vaultwarden_volume" {
  source = "github.com/linolabx/terraform-modules-k8s//local-volume"

  namespace        = kubernetes_namespace.this.metadata.0.name
  name             = "vaultwarden-data-vol"
  storage_host     = "vault"
  storage_endpoint = "k3s-data"
  capacity         = "16Gi"
}

resource "random_password" "admin_token" {
  length  = 48
  special = false
}

resource "random_password" "vaultwarden_postgres_userpass" {
  length  = 24
  special = false
}

resource "kubernetes_deployment" "vaultwarden_deployment" {
  metadata {
    namespace = kubernetes_namespace.this.metadata.0.name
    name      = "vaultwarden-deployment"
    labels    = { app = "vaultwarden" }
  }
  wait_for_rollout = true

  spec {
    replicas = 1
    selector { match_labels = { app = "vaultwarden" } }
    template {
      metadata { labels = { app = "vaultwarden" } }
      spec {
        node_selector = { "kubernetes.io/hostname" = "vault" }

        volume {
          name = "vaultwarden-data-vol"
          persistent_volume_claim { claim_name = module.vaultwarden_volume.pvc_name }
        }

        container {
          name  = "postgres"
          image = "postgres:15-alpine"

          env {
            name  = "POSTGRES_DB"
            value = "vaultwarden"
          }

          env {
            name  = "POSTGRES_USER"
            value = "vaultwarden"
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = random_password.vaultwarden_postgres_userpass.result
          }

          volume_mount {
            name       = "vaultwarden-data-vol"
            sub_path   = "postgres"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        container {
          name  = "vaultwarden"
          image = "vaultwarden/server:latest"
          port { container_port = 80 }

          volume_mount {
            name       = "vaultwarden-data-vol"
            sub_path   = "vaultwarden"
            mount_path = "/data"
          }

          dynamic "env" {
            for_each = {
              TZ                  = "Asia/Shanghai"
              SIGNUPS_ALLOWED     = "false"
              INVITATIONS_ALLOWED = "true"
              SHOW_PASSWORD_HINT  = "false"
              ADMIN_TOKEN         = random_password.admin_token.result
              DOMAIN              = "https://bitwarden.geektr.co"
              DATABASE_URL        = "postgres://vaultwarden:${random_password.vaultwarden_postgres_userpass.result}@localhost:5432/vaultwarden"
            }
            content {
              name  = env.key
              value = env.value
            }
          }
        }
      }
    }
  }
}

module "vaultwarden_ingress" {
  source = "github.com/linolabx/terraform-modules-k8s//ingress-traefik"

  namespace = kubernetes_namespace.this.metadata.0.name

  app = {
    name = "vaultwarden"
    port = 80
  }

  domain = "bitwarden.geektr.co"

  issuer = "letsencrypt-prod"
  tls = {
    hosts       = ["*.geektr.co"]
    secret_name = "tls-co-geektr"
  }

  redirect_https = true
}

resource "alicloud_alidns_record" "vaultwarden_public" {
  domain_name = "geektr.co"
  rr          = "bitwarden"
  value       = "vault.geektr.co"
  type        = "CNAME"
}
