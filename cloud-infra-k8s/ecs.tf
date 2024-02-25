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
    fqdn_public   = "psyduck.pokemon.geektr.co"
    fqdn_private  = "psyduck.pokemon.intl.geektr.co"
    instance_name = "${local.infra_id}-pokemon-psyduck"
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
  resource_group_id    = local.resource_group_id
}

resource "alicloud_instance" "psyduck" {
  instance_name = local.psyduck.instance_name
  description   = "Managed by Terraform: main server of pokemon k3s cluster"

  resource_group_id = local.resource_group_id

  instance_type = "ecs.t5-c1m2.xlarge"

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

  instance_charge_type = "PrePaid"
  period_unit          = "Month"
  period               = 1
  renewal_status       = "AutoRenewal"
  auto_renew_period    = 1
  credit_specification = "Unlimited"

  host_name = local.psyduck.hostname
  user_data = templatefile("${path.module}/ecs-cloud-init", {
    hostname     = local.psyduck.hostname
    fqdn_private = local.psyduck.fqdn_private

    k3s_config = {
      node-name             = local.psyduck.hostname
      write-kubeconfig-mode = "0644"
      node-ip               = "0.0.0.0"
      node-external-ip      = alicloud_eip_address.psyduck.ip_address
      tls-san = [
        local.psyduck.fqdn_private,
        local.psyduck.fqdn_public,
      ]
      node-label = [
        "pokemon.geektr.co/infra-id=${local.infra_id}",
        "pokemon.geektr.co/datacenter=cloud",
        "pokemon.geektr.co/cluster-id=pokemon",
        "pokemon.geektr.co/node-id=psyduck",
        "aliyun.com/region=${module.alicloud.region}",
      ],
      kube-apiserver-arg      = "service-node-port-range=1-65535"
      kubelet-arg             = "node-ip=::"
      system-default-registry = "registry.cn-hangzhou.aliyuncs.com"
      agent-token             = random_password.pokemon_agent_token.result
    }
  })

  security_enhancement_strategy = "Deactive"
}

resource "alicloud_eip_association" "psyduck" {
  allocation_id = alicloud_eip_address.psyduck.id
  instance_id   = alicloud_instance.psyduck.id
}

resource "alicloud_alidns_record" "psyduck_public" {
  domain_name = "geektr.co"
  rr          = trimsuffix(local.psyduck.fqdn_public, ".geektr.co")
  value       = alicloud_eip_address.psyduck.ip_address
  type        = "A"
}

resource "alicloud_alidns_record" "psyduck_private" {
  domain_name = "geektr.co"
  rr          = trimsuffix(local.psyduck.fqdn_private, ".geektr.co")
  value       = alicloud_instance.psyduck.primary_ip_address
  type        = "A"
}
