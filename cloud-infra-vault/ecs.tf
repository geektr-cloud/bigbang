# Image
data "alicloud_images" "debian_12" {
  owners       = "system"
  architecture = "x86_64"
  name_regex   = "^debian_12"
  most_recent  = true
}

# K3S
resource "random_password" "k3s_agent_token" {
  length  = 32
  special = false
}

# Instance
locals {
  vault = {
    hostname      = "vault"
    fqdn_public   = "vault.geektr.co"
    fqdn_private  = "vault.intl.geektr.co"
    instance_name = "${local.infra_id}-vault"
  }
}

resource "alicloud_eip_address" "vault" {
  address_name         = local.vault.instance_name
  description          = "Managed by Terraform"
  isp                  = "BGP"
  netmode              = "public"
  bandwidth            = "200"
  payment_type         = "PayAsYouGo"
  internet_charge_type = "PayByTraffic"
  deletion_protection  = true
  resource_group_id    = local.infra_resource_group_id
}

resource "alicloud_instance" "vault" {
  instance_name = local.vault.instance_name
  description   = "Managed by Terraform: vault server, single node k3s cluster"

  resource_group_id = local.infra_resource_group_id

  instance_type = "ecs.t6-c1m1.large"

  vswitch_id = local.vswitch.id

  security_groups = [alicloud_security_group.vault_public.id]

  system_disk_category    = "cloud_efficiency"
  system_disk_size        = 32
  system_disk_name        = local.vault.instance_name
  system_disk_description = "${local.vault.instance_name}-system"
  image_id                = data.alicloud_images.debian_12.images.0.id

  data_disks {
    name                 = "data"
    size                 = 32
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

  host_name = "vault"
  user_data = templatefile("${path.module}/ecs-cloud-init", {
    hostname     = local.vault.hostname
    fqdn_private = local.vault.fqdn_private

    k3s_config = {
      node-name             = local.vault.hostname
      write-kubeconfig-mode = "0644"
      node-ip               = "0.0.0.0"
      node-external-ip      = alicloud_eip_address.vault.ip_address
      tls-san = [
        local.vault.fqdn_private,
        local.vault.fqdn_public,
      ]
      node-label = [
        "k8s.geektr.co/infra-id=${local.infra_id}",
        "k8s.geektr.co/datacenter=cloud",
        "k8s.geektr.co/cluster-id=vault",
        "aliyun.com/region=${var.ali_primary_region}",
      ],
      kube-apiserver-arg      = "service-node-port-range=1-65535"
      kubelet-arg             = "node-ip=::"
      system-default-registry = "registry.cn-hangzhou.aliyuncs.com"
      agent-token             = random_password.k3s_agent_token.result
    }
  })

  security_enhancement_strategy = "Deactive"
}

resource "alicloud_eip_association" "vault" {
  allocation_id = alicloud_eip_address.vault.id
  instance_id   = alicloud_instance.vault.id
}

resource "alicloud_alidns_record" "vault_public" {
  domain_name = "geektr.co"
  rr          = trimsuffix(local.vault.fqdn_public, ".geektr.co")
  value       = alicloud_eip_address.vault.ip_address
  type        = "A"
}

resource "alicloud_alidns_record" "vault_private" {
  domain_name = "geektr.co"
  rr          = trimsuffix(local.vault.fqdn_private, ".geektr.co")
  value       = alicloud_instance.vault.primary_ip_address
  type        = "A"
}
