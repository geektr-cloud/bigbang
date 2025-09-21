locals {
  keys_file = fileset(provider::tfproj::format("{secret.path}/public/keys"), "*.pub")
  keys_map = {
    for filename in local.keys_file : trimsuffix(filename, ".pub") => file(provider::tfproj::ensure("{secret.path}/public/keys/${filename}"))
  }
}

resource "alicloud_ecs_key_pair" "keys" {
  for_each = local.keys_map

  key_pair_name     = each.key
  public_key        = each.value
  resource_group_id = alicloud_resource_manager_resource_group.infra.id
}
