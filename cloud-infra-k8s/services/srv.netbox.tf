resource "kubernetes_persistent_volume_claim" "netbox" {
  metadata {
    namespace = kubernetes_namespace.this.metadata.0.name
    name      = "netbox"
  }
  wait_until_bound = false
  spec {
    storage_class_name = "openebs-hostpath"
    access_modes       = ["ReadWriteOnce"]
    resources { requests = { storage = "42Gi" } }
  }
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

resource "kubernetes_deployment" "netbox" {
  metadata {
    namespace = kubernetes_namespace.this.metadata.0.name
    name      = "netbox"
    labels    = { app = "netbox" }
  }
  wait_for_rollout = true

  spec {
    replicas = 1
    selector { match_labels = { app = "netbox" } }
    strategy { type = "Recreate" }
    template {
      metadata { labels = { app = "netbox" } }
      spec {
        node_selector = { "kubernetes.io/hostname" = "psyduck" }

        volume {
          name = "netbox"
          persistent_volume_claim { claim_name = kubernetes_persistent_volume_claim.netbox.metadata.0.name }
        }

        init_container {
          name  = "netbox-init"
          image = "alpine:3"

          command = ["sh", "-c", "cd /opt/netbox/netbox && mkdir -p config media postgres redis reports scripts && chown -R 999:999 media reports scripts"]

          volume_mount {
            name       = "netbox"
            mount_path = "/opt/netbox/netbox"
          }
        }

        container {
          name  = "redis"
          image = "redis:7-alpine"

          volume_mount {
            name       = "netbox"
            sub_path   = "redis"
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
            name       = "netbox"
            sub_path   = "postgres"
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
            name       = "netbox"
            sub_path   = "media"
            mount_path = "/opt/netbox/netbox/media"
          }

          volume_mount {
            name       = "netbox"
            sub_path   = "reports"
            mount_path = "/opt/netbox/netbox/reports"
          }

          volume_mount {
            name       = "netbox"
            sub_path   = "scripts"
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
            name       = "netbox"
            sub_path   = "media"
            mount_path = "/opt/netbox/netbox/media"
          }

          volume_mount {
            name       = "netbox"
            sub_path   = "reports"
            mount_path = "/opt/netbox/netbox/reports"
          }

          volume_mount {
            name       = "netbox"
            sub_path   = "scripts"
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
            name       = "netbox"
            sub_path   = "media"
            mount_path = "/opt/netbox/netbox/media"
          }

          volume_mount {
            name       = "netbox"
            sub_path   = "reports"
            mount_path = "/opt/netbox/netbox/reports"
          }

          volume_mount {
            name       = "netbox"
            sub_path   = "scripts"
            mount_path = "/opt/netbox/netbox/scripts"
          }
        }
      }
    }
  }
}

module "netbox_ingress" {
  source = "github.com/linolabx/tfmodules?ref=k8s-ingress-traefik@v0.0.6"

  namespace    = kubernetes_namespace.this.metadata.0.name
  issuer       = local.k8s.issuer
  cert_domains = [local.infra.base_domain]

  hostmap = [
    { domain = "netbox.${local.infra.base_domain}", app = "netbox", port = 8080 },
  ]
}

resource "cloudflare_record" "netbox_public" {
  zone_id = local.cloudflare.base_domain_zone.id
  name    = "netbox"
  type    = "CNAME"
  content = local.k8s.cname
}
