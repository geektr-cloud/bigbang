# https://raw.githubusercontent.com/pragkent/alidns-webhook/master/deploy/bundle.yaml
data "kubectl_path_documents" "alidns_webhook_yml" { pattern = "./cert-alidns-webhook.yml" }
resource "kubectl_manifest" "alidns_webhook" {
  for_each  = data.kubectl_path_documents.alidns_webhook_yml.manifests
  yaml_body = each.value
}

resource "kubernetes_secret" "alidns_credential" {
  metadata {
    name      = "alidns-credential"
    namespace = "cert-manager"
  }

  data = {
    access_key = alicloud_ram_access_key.cert_manager.id
    secret_key = alicloud_ram_access_key.cert_manager.secret
  }
}


resource "kubernetes_manifest" "clusterissuer_cert_manager_letsencrypt_prod" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = { name = "letsencrypt-prod" }

    spec = {
      acme = {
        email               = "acme@geektr.co"
        privateKeySecretRef = { name = "letsencrypt-prod-account-key" }
        server              = "https://acme-v02.api.letsencrypt.org/directory"
        solvers = [{
          dns01 = {
            webhook = {
              groupName  = "acme.geektr.co"
              solverName = "alidns"
              config = {
                region = ""
                accessKeySecretRef = {
                  name = kubernetes_secret.alidns_credential.metadata[0].name
                  key  = "access_key"
                }
                secretKeySecretRef = {
                  name = kubernetes_secret.alidns_credential.metadata[0].name
                  key  = "secret_key"
                }
              }
            }
          }
        }]
      }
    }
  }
}
