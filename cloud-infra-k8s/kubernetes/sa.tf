locals {
  cluster_name = "pokemon"
}

module "issuer" {
  source = "/home/geektr/projects/github.com/linolabx/tfmodules/k8s-issuer-cluster-cf"

  cluster_name = local.cluster_name
  identifier   = "global"

  acme = { email = data.vault_kv_secret_v2.cloudflare.data["email"] }

  zones = [local.cloudflare.base_domain_zone]
}

resource "kubernetes_service_account" "terraform_admin" {
  metadata {
    name      = "terraform-admin"
    namespace = "kube-system"
  }
  automount_service_account_token = true
}

resource "kubernetes_secret" "terraform_admin" {
  metadata {
    name        = "terraform-admin"
    namespace   = "kube-system"
    annotations = { "kubernetes.io/service-account.name" = "terraform-admin" }
  }
  type = "kubernetes.io/service-account-token"

  wait_for_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "terraform_admin" {
  metadata { name = "terraform-admin" }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "terraform-admin"
    namespace = "kube-system"
  }
}

resource "vault_kv_secret_v2" "k8s" {
  mount = local.creds.vault.mount
  name  = "infra/k8s-pokemon/tokens/terraform-admin"

  delete_all_versions = true

  data_json = jsonencode({
    public_host            = data.vault_kv_secret_v2.k8s.data["public_host"]
    host                   = data.vault_kv_secret_v2.k8s.data["host"]
    cluster_ca_certificate = data.vault_kv_secret_v2.k8s.data["cluster_ca_certificate"]
    token                  = kubernetes_secret.terraform_admin.data["token"]
    infra = {
      issuer = module.issuer.issuer
      cname  = "psyduck.pokemon.${local.infra.base_domain}"
    }
  })
}
