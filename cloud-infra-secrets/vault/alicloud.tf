module "alicloud_admin" {
  source = "github.com/geektheripper/terraform-helpers//providers/alicloud/vault/new"

  vault_mount = vault_mount.terraform.path
  vault_key   = "infra/alicloud-geektr/keys/terraform-admin"

  region = "cn-shanghai"

  user_name   = "${local.infra.id}.terraform-admin"
  policy_name = "AdministratorAccess"

  extra = {
    infra_id          = local.infra.id
    vpc               = local.infra.aliyun.vpc
    vswitches         = local.infra.aliyun.vswitches
    resource_group_id = local.infra.aliyun.resource_group.id
  }
}
