resource "kubernetes_service" "vault_svc" {
  metadata {
    name      = "vault-svc"
    namespace = "vault"
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 8200
      target_port = "8200"
    }
  }
}

resource "kubernetes_endpoints" "vault_svc" {
  metadata {
    name      = "vault-svc"
    namespace = "vault"
  }

  subset {
    address { ip = "10.42.1.1" }
    port { port = 8200 }
  }
}

resource "kubernetes_endpoint_slice_v1" "vault_svc" {
  metadata {
    name      = "vault-svc-1"
    namespace = "vault"
    labels    = { "kubernetes.io/service-name" = "vault-svc" }
  }

  address_type = "IPv4"

  endpoint {
    addresses = ["10.42.1.1"]
  }

  port {
    app_protocol = "http"
    protocol     = "TCP"
    port         = 8200
  }
}

module "vault_ingress" {
  # source = "github.com/linolabx/terraform-modules-k8s//ingress-traefik"
  source = "/home/geektr/projects/github.com/linolabx/terraform-modules-k8s/ingress-traefik"

  namespace = kubernetes_namespace.this.metadata.0.name

  service = {
    name = "vault-svc"
    port = { number = 8200 }
  }

  domain = "vault.geektr.co"

  issuer = "letsencrypt-prod"
  tls = {
    hosts       = ["*.geektr.co"]
    secret_name = "tls-co-geektr"
  }

  redirect_https = true
}
