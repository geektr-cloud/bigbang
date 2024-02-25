data "terraform_remote_state" "cloud_infra" {
  backend = "local"
  config  = { path = "../../.secret/tfstates/cloud-infra/terraform.tfstate" }
}

module "alicloud_admin" {
  source = "/home/geektr/projects/github.com/geektheripper/terraform-helpers/providers/alicloud/vault/new"

  vault_mount = vault_mount.terraform.path
  vault_key   = "infra/alicloud-geektr/keys/terraform-admin"

  region = "cn-shanghai"

  user_name   = "${var.infra_id}.terraform-admin"
  policy_name = "AdministratorAccess"

  extra = {
    infra_id          = var.infra_id
    vpc               = data.terraform_remote_state.cloud_infra.outputs.infra_vpc
    vswitches         = data.terraform_remote_state.cloud_infra.outputs.infra_vpc_vswitches
    resource_group_id = data.terraform_remote_state.cloud_infra.outputs.infra_resource_group_id
  }
}
