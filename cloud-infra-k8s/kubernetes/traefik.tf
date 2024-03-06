resource "kubernetes_manifest" "traefik_middleware_redirect_https" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"
    metadata = {
      namespace = "kube-system"
      name      = "redirect-https"
    }
    spec = {
      redirectScheme = {
        scheme    = "https"
        permanent = true
      }
    }
  }
}

locals {
  middlewares = {
    redirect_https = "${kubernetes_manifest.traefik_middleware_redirect_https.manifest.metadata.namespace}-${kubernetes_manifest.traefik_middleware_redirect_https.manifest.metadata.name}@kubernetescrd"
  }
}
