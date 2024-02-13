locals { cloud_cidr = "10.16.0.0/12" }

resource "alicloud_vpc" "infra" {
  vpc_name          = local.infra_id
  cidr_block        = cidrsubnet(local.cloud_cidr, 8, 4)
  enable_ipv6       = true
  description       = "Managed by Terraform"
  resource_group_id = alicloud_resource_manager_resource_group.infra.id
}

data "alicloud_zones" "this" { available_resource_creation = "VSwitch" }

# TODO: https://smartservice.console.aliyun.com/service/chat?id=0001ZBCCN6
locals {
  alicloud_zones_ids = toset([
    "cn-shanghai-a",
    "cn-shanghai-b",
    "cn-shanghai-c",
    "cn-shanghai-d",
    "cn-shanghai-e",
    "cn-shanghai-f",
    "cn-shanghai-g",
    "cn-shanghai-l",
    "cn-shanghai-m",
    "cn-shanghai-n",
  ])
}

# substr(id, -1, 1)
# get last character of id, for example: cn-shanghai-a => a
# 
# parseint(v, 46) - 10
# convert v to letter index, for example: a => 0
resource "alicloud_vswitch" "infra" {
  # for_each = toset(data.alicloud_zones.this.ids)
  for_each = local.alicloud_zones_ids

  vpc_id       = alicloud_vpc.infra.id
  zone_id      = each.key
  vswitch_name = "infra-${each.key}"

  cidr_block  = cidrsubnet(alicloud_vpc.infra.cidr_block, 4, parseint(substr(each.key, -1, 1), 46) - 10)
  enable_ipv6 = true
  # TODO: remove +1, https://github.com/aliyun/terraform-provider-alicloud/pull/6544
  ipv6_cidr_block_mask = parseint(substr(each.key, -1, 1), 46) - 10 + 1

  # TODO: add resource_group_id
  # resource_group_id = alicloud_resource_manager_resource_group.infra.id
}
