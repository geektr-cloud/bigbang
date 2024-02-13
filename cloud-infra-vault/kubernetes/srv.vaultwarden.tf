module "vaultwarden_volume" {
  source = "github.com/linolabx/terraform-modules-k8s//local-volume"

  namespace        = kubernetes_namespace.this.metadata.0.name
  name             = "vaultwarden-data-vol"
  storage_host     = "vault"
  storage_endpoint = "k3s-data"
  capacity         = "16Gi"
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
          name  = "vaultwarden"
          image = "vaultwarden/server:latest"
          port { container_port = 80 }

          volume_mount {
            name       = "vaultwarden-data-vol"
            mount_path = "/data"
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
