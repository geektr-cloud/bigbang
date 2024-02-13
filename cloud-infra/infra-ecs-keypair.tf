resource "alicloud_ecs_key_pair" "root" {
  key_pair_name     = "root"
  public_key        = file("../.secret/root.pub")
  resource_group_id = alicloud_resource_manager_resource_group.infra.id
}

resource "alicloud_ecs_key_pair" "geektr" {
  key_pair_name     = "geektr"
  public_key        = file("../.secret/geektr.pub")
  resource_group_id = alicloud_resource_manager_resource_group.infra.id
}
