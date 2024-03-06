module "kubernetes_admin" {
  source = "github.com/geektheripper/terraform-helpers//providers/k8s/vault-sa/new"

  vault_mount = module.vault.mount
  vault_key   = "infra/kubernetes-pokemon/tokens/terraform-admin"

  name      = "terraform-admin"
  namespace = "kube-system"

  host                   = data.vault_kv_secret_v2.this.data["host"]
  cluster_ca_certificate = data.vault_kv_secret_v2.this.data["cluster_ca_certificate"]

  extra = {
    primary_domain = "psyduck.pokemon.geektr.co"
    cluster_issuer = "letsencrypt-prod"
  }
}

resource "kubernetes_cluster_role_binding" "terraform_admin" {
  metadata { name = module.kubernetes_admin.name }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = module.kubernetes_admin.name
    namespace = module.kubernetes_admin.namespace
  }
}
