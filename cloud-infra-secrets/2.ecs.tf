# Image
data "alicloud_images" "debian_12" {
  owners       = "system"
  architecture = "x86_64"
  name_regex   = "^debian_12"
  most_recent  = true
}

# Instance
locals {
  closet = {
    instance_name = "${local.infra.id}-closet"
    hostname      = "closet"
  }
}

resource "alicloud_eip_address" "closet" {
  address_name         = local.closet.instance_name
  description          = "Managed by Terraform"
  isp                  = "BGP"
  netmode              = "public"
  bandwidth            = "200"
  payment_type         = "PayAsYouGo"
  internet_charge_type = "PayByTraffic"
  deletion_protection  = true
  resource_group_id    = local.aliyun.resource_group.id
}

resource "alicloud_ecs_auto_snapshot_policy" "closet" {
  auto_snapshot_policy_name = "${local.infra.id}-closet"
  repeat_weekdays           = ["1", "2", "3", "4", "5", "6", "7"]
  retention_days            = 30
  time_points               = ["4", "16"]
}

resource "alicloud_instance" "closet" {
  lifecycle {
    ignore_changes = [
      image_id,
      # alicloud provider will destory disk and instance then recreate
      # when apply snapshot_policy to existing disk
      # so manual set auto_snapshot_policy_id in web console
      # fuck alicloud
      data_disks[0].auto_snapshot_policy_id
    ]
  }

  instance_name = local.closet.instance_name
  description   = "Managed by Terraform: closet server, manage all secrets"

  resource_group_id = local.aliyun.resource_group.id

  instance_type = "ecs.t6-c1m2.large"

  vswitch_id = local.vswitch.id

  security_groups = [alicloud_security_group.closet_public.id]

  system_disk_category    = "cloud_efficiency"
  system_disk_size        = 20
  system_disk_name        = local.closet.instance_name
  system_disk_description = "${local.closet.instance_name}-system"
  image_id                = data.alicloud_images.debian_12.images.0.id

  data_disks {
    name                    = "data"
    size                    = 32
    auto_snapshot_policy_id = alicloud_ecs_auto_snapshot_policy.closet.id
    delete_with_instance    = false
    category                = "cloud_efficiency"
    description             = "data"
  }

  instance_charge_type = "PostPaid"
  credit_specification = "Unlimited"

  host_name = local.closet.hostname
  user_data = "#cloud-config\n${yamlencode(local.closet_user_data)}"

  security_enhancement_strategy = "Deactive"
}

resource "alicloud_eip_association" "closet" {
  allocation_id = alicloud_eip_address.closet.id
  instance_id   = alicloud_instance.closet.id
}
