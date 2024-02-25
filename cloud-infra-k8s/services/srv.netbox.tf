module "netbox_volumes" {
  for_each = toset(["redis", "postgres", "config", "media", "reports", "scripts"])

  source = "github.com/linolabx/terraform-modules-k8s//local-volume"

  namespace        = kubernetes_namespace.this.metadata.0.name
  name             = "netbox-${each.key}-vol"
  storage_host     = "psyduck"
  storage_endpoint = "k3s-data"
  capacity         = "16Gi"
}

resource "random_password" "netbox_postgres_userpass" {
  length  = 24
  special = false
}

resource "random_password" "netbox_secret_key" {
  length  = 64
  special = false
}

locals {
  netbox_env = {
    DB_HOST = "127.0.0.1"
    DB_NAME = "netbox"
    DB_USER = "netbox"
    DB_PASS = random_password.netbox_postgres_userpass.result

    GRAPHQL_ENABLED       = "true"
    HOUSEKEEPING_INTERVAL = "86400"

    REDIS_DATABASE                 = "0"
    REDIS_HOST                     = "127.0.0.1"
    REDIS_INSECURE_SKIP_TLS_VERIFY = "false"
    REDIS_PASSWORD                 = ""
    REDIS_SSL                      = "false"

    REDIS_CACHE_DATABASE                 = "1"
    REDIS_CACHE_HOST                     = "127.0.0.1"
    REDIS_CACHE_INSECURE_SKIP_TLS_VERIFY = "false"
    REDIS_CACHE_PASSWORD                 = ""
    REDIS_CACHE_SSL                      = "false"

    RELEASE_CHECK_URL = "https://api.github.com/repos/netbox-community/netbox/releases"
    SECRET_KEY        = random_password.netbox_secret_key.result
    SKIP_SUPERUSER    = "true"
    WEBHOOKS_ENABLED  = "true"

    MEDIA_ROOT   = "/opt/netbox/netbox/media"
    SCRIPTS_ROOT = "/opt/netbox/netbox/scripts"
    REPORTS_ROOT = "/opt/netbox/netbox/reports"
  }
}

resource "kubernetes_deployment" "netbox_deployment" {
  metadata {
    namespace = kubernetes_namespace.this.metadata.0.name
    name      = "netbox-deployment"
    labels    = { app = "netbox" }
  }
  wait_for_rollout = true

  spec {
    replicas = 1
    selector { match_labels = { app = "netbox" } }
    template {
      metadata { labels = { app = "netbox" } }
      spec {
        node_selector = { "kubernetes.io/hostname" = "psyduck" }

        dynamic "volume" {
          for_each = module.netbox_volumes
          content {
            name = "netbox-${volume.key}-vol"
            persistent_volume_claim { claim_name = volume.value.pvc_name }
          }
        }

        init_container {
          name  = "netbox-init"
          image = "alpine:3"

          command = ["chown", "-R", "999:999", "/opt/netbox/netbox/media", "/opt/netbox/netbox/reports", "/opt/netbox/netbox/scripts"]

          volume_mount {
            name       = "netbox-media-vol"
            mount_path = "/opt/netbox/netbox/media"
          }

          volume_mount {
            name       = "netbox-reports-vol"
            mount_path = "/opt/netbox/netbox/reports"
          }

          volume_mount {
            name       = "netbox-scripts-vol"
            mount_path = "/opt/netbox/netbox/scripts"
          }
        }

        container {
          name  = "redis"
          image = "redis:7-alpine"

          volume_mount {
            name       = "netbox-redis-vol"
            mount_path = "/data"
          }
        }

        container {
          name  = "postgres"
          image = "postgres:15-alpine"

          env {
            name  = "POSTGRES_DB"
            value = "netbox"
          }

          env {
            name  = "POSTGRES_USER"
            value = "netbox"
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = random_password.netbox_postgres_userpass.result
          }

          volume_mount {
            name       = "netbox-postgres-vol"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        container {
          name  = "netbox"
          image = "netboxcommunity/netbox:v3.7.2-2.8.0"

          port { container_port = 8080 }

          dynamic "env" {
            for_each = local.netbox_env
            content {
              name  = env.key
              value = env.value
            }
          }

          volume_mount {
            name       = "netbox-media-vol"
            mount_path = "/opt/netbox/netbox/media"
          }

          volume_mount {
            name       = "netbox-reports-vol"
            mount_path = "/opt/netbox/netbox/reports"
          }

          volume_mount {
            name       = "netbox-scripts-vol"
            mount_path = "/opt/netbox/netbox/scripts"
          }
        }

        container {
          name    = "netbox-agent"
          image   = "netboxcommunity/netbox:v3.7.2-2.8.0"
          command = ["/opt/netbox/venv/bin/python", "/opt/netbox/netbox/manage.py", "rqworker"]

          dynamic "env" {
            for_each = local.netbox_env
            content {
              name  = env.key
              value = env.value
            }
          }

          volume_mount {
            name       = "netbox-media-vol"
            mount_path = "/opt/netbox/netbox/media"
          }

          volume_mount {
            name       = "netbox-reports-vol"
            mount_path = "/opt/netbox/netbox/reports"
          }

          volume_mount {
            name       = "netbox-scripts-vol"
            mount_path = "/opt/netbox/netbox/scripts"
          }
        }

        container {
          name    = "netbox-housekeeping"
          image   = "netboxcommunity/netbox:v3.7.2-2.8.0"
          command = ["/opt/netbox/housekeeping.sh"]

          dynamic "env" {
            for_each = local.netbox_env
            content {
              name  = env.key
              value = env.value
            }
          }

          volume_mount {
            name       = "netbox-media-vol"
            mount_path = "/opt/netbox/netbox/media"
          }

          volume_mount {
            name       = "netbox-reports-vol"
            mount_path = "/opt/netbox/netbox/reports"
          }

          volume_mount {
            name       = "netbox-scripts-vol"
            mount_path = "/opt/netbox/netbox/scripts"
          }
        }
      }
    }
  }
}

module "netbox_ingress" {
  source = "github.com/linolabx/terraform-modules-k8s//ingress-traefik"

  namespace = kubernetes_namespace.this.metadata.0.name

  app = {
    name = "netbox"
    port = 8080
  }

  domain = "netbox.geektr.co"

  issuer = module.kubernetes.extra.cluster_issuer
  tls = {
    hosts       = ["*.geektr.co"]
    secret_name = "tls-co-geektr"
  }

  redirect_https = true
}

resource "alicloud_alidns_record" "netbox_public" {
  domain_name = "geektr.co"
  rr          = "netbox"
  value       = module.kubernetes.extra.primary_domain
  type        = "CNAME"
}
