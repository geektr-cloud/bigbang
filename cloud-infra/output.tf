output "infra_id" { value = local.infra_id }
output "infra_fc_srv" { value = alicloud_fc_service.infra_fc.name }
output "infra_vpc" { value = alicloud_vpc.infra }
output "infra_vpc_vswitches" { value = alicloud_vswitch.infra }
output "infra_ecs_sg" { value = {
  pub_web = alicloud_security_group.infra_public_web
} }
output "infra_ecs_keypair" { value = {
  root   = alicloud_ecs_key_pair.root
  geektr = alicloud_ecs_key_pair.geektr
} }
output "infra_resource_group_id" { value = alicloud_resource_manager_resource_group.infra.id }
