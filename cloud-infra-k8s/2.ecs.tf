# Image
data "alicloud_images" "debian_12" {
  owners       = "system"
  architecture = "x86_64"
  name_regex   = "^debian_12"
  most_recent  = true
}

# K3S
resource "random_password" "pokemon_agent_token" {
  length  = 32
  special = false
}

# Instance
locals {
  psyduck = {
    hostname      = "psyduck"
    fqdn_public   = "psyduck.pokemon.${local.infra.base_domain}"
    fqdn_private  = "psyduck.pokemon.intl.${local.infra.base_domain}"
    instance_name = "${local.infra.id}-pokemon-psyduck"
  }
}

resource "alicloud_eip_address" "psyduck" {
  address_name         = local.psyduck.instance_name
  description          = "Managed by Terraform"
  isp                  = "BGP"
  netmode              = "public"
  bandwidth            = "200"
  payment_type         = "PayAsYouGo"
  internet_charge_type = "PayByTraffic"
  deletion_protection  = true
  resource_group_id    = local.aliyun.resource_group.id
}

resource "alicloud_instance" "psyduck" {
  instance_name = local.psyduck.instance_name
  description   = "Managed by Terraform: main server of pokemon k3s cluster"

  lifecycle { ignore_changes = [image_id, user_data] }

  resource_group_id = local.aliyun.resource_group.id

  instance_type = "ecs.t6-c1m4.xlarge"

  vswitch_id = local.vswitch.id

  security_groups = [alicloud_security_group.pokemon_public.id]

  system_disk_category    = "cloud_efficiency"
  system_disk_size        = 64
  system_disk_name        = local.psyduck.instance_name
  system_disk_description = "${local.psyduck.instance_name}-system"
  image_id                = data.alicloud_images.debian_12.images.0.id

  data_disks {
    name                 = "data"
    size                 = 64
    delete_with_instance = false
    category             = "cloud_efficiency"
    description          = "data"
  }

  instance_charge_type = "PostPaid"
  credit_specification = "Unlimited"

  host_name = local.psyduck.hostname
  user_data = yamlencode(local.instance_user_data)

  security_enhancement_strategy = "Deactive"
}

resource "alicloud_eip_association" "psyduck" {
  allocation_id = alicloud_eip_address.psyduck.id
  instance_id   = alicloud_instance.psyduck.id
}

resource "cloudflare_record" "psyduck" {
  zone_id = local.cloudflare.base_domain_zone.id
  name    = local.psyduck.fqdn_public
  type    = "A"
  content = alicloud_eip_address.psyduck.ip_address
  ttl     = 1
  proxied = false
}

resource "cloudflare_record" "psyduck_private" {
  zone_id = local.cloudflare.base_domain_zone.id
  name    = local.psyduck.fqdn_private
  type    = "A"
  content = alicloud_instance.psyduck.primary_ip_address
  ttl     = 1
  proxied = false
}
