locals {
  keys_file = fileset(provider::tfproj::format("{secret.path}/public/keys"), "*.pub")
  keys_map = {
    for filename in local.keys_file : trimsuffix(filename, ".pub") => file(provider::tfproj::ensure("{secret.path}/public/keys/${filename}"))
  }
}

locals {
  instance_init_script = <<-EOSCRIPT
  #!/bin/bash -e

  sed -i "s/__node_ip__/$(hostname -I | cut -d' ' -f1)/g" /etc/rancher/k3s/config.yaml

  curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \
        INSTALL_K3S_MIRROR=cn sh -s - \
        --system-default-registry "dcr.oci.anitya.net"

  # Clean
  rm /instance-init.sh
  EOSCRIPT
}

locals {
  instance_user_data = {
    # Storage
    disk_setup = {
      "/dev/vdb" = {
        table_type = "gpt"
        layout     = false
        overwrite  = true
      }
    }
    fs_setup = [{
      label      = "k3s-data"
      filesystem = "ext4"
      device     = "/dev/vdb"
    }]
    mounts = [["/dev/vdb", "/mnt/k3s-data"]]

    # Network
    timezone                  = "Asia/Shanghai"
    hostname                  = local.psyduck.hostname
    fqdn                      = local.psyduck.fqdn_private
    prefer_fqdn_over_hostname = true

    # Users
    ssh_pwauth = false
    ssh_authorized_keys = concat(
      [file(provider::tfproj::ensure("{secret.path}/terraform.pub"))],
      can(local.keys_map["root"]) ? [local.keys_map["root"]] : []
    )

    users = concat(
      [{
        name                = "terraform"
        primary_group       = "terraform"
        shell               = "/bin/bash"
        groups              = ["sudo"]
        sudo                = "ALL=(ALL) NOPASSWD:ALL"
        lock_passwd         = true
        ssh_authorized_keys = [file(provider::tfproj::ensure("{secret.path}/terraform.pub"))]
      }],
      [for u, k in local.keys_map : {
        name                = u
        primary_group       = u
        shell               = "/bin/bash"
        groups              = ["sudo"]
        sudo                = "ALL=(ALL) NOPASSWD:ALL"
        lock_passwd         = true
        ssh_authorized_keys = [k]
      } if u != "root"]
    )

    write_files = [{
      path        = "/etc/rancher/k3s/registries.yaml"
      owner       = "root:root"
      permissions = "0644"
      content     = file("${path.module}/../presets/k3s/registries.yaml")
      }, {
      path        = "/var/lib/rancher/k3s/server/manifests/cert-manager.yaml"
      owner       = "root:root"
      permissions = "0644"
      content     = file("${path.module}/../presets/k3s/cert-manager.yaml")
      }, {
      path        = "/var/lib/rancher/k3s/server/manifests/keel.yaml"
      owner       = "root:root"
      permissions = "0644"
      content     = file("${path.module}/../presets/k3s/keel.yaml")
      }, {
      path        = "/var/lib/rancher/k3s/server/manifests/openebs.yaml"
      owner       = "root:root"
      permissions = "0644"
      content     = file("${path.module}/../presets/k3s/openebs-localpv.yaml")
      }, {
      path        = "/instance-init.sh"
      owner       = "root:root"
      permissions = "0700"
      content     = local.instance_init_script
      }, {
      path  = "/etc/rancher/k3s/config.yaml"
      owner = "root:root"
      content = yamlencode({
        node-name             = local.psyduck.hostname
        write-kubeconfig-mode = "0644"
        node-ip               = "__node_ip__"
        node-external-ip      = alicloud_eip_address.psyduck.ip_address
        tls-san = [
          local.psyduck.fqdn_private,
          local.psyduck.fqdn_public,
        ]
        node-label = [
          "pokemon.geektr.co/infra-id=${local.infra.id}",
          "pokemon.geektr.co/datacenter=cloud",
          "pokemon.geektr.co/cluster-id=pokemon",
          "pokemon.geektr.co/node-id=psyduck",
          "aliyun.com/region=${local.aliyun.region}",
        ],
        kube-apiserver-arg      = "service-node-port-range=1-65535"
        system-default-registry = "dcr.oci.anitya.net"
        agent-token             = random_password.pokemon_agent_token.result
      })
    }]

    package_update  = true
    package_upgrade = true
    packages        = ["axel", "curl", "dnsutils", "git-lfs", "htop", "jq", "mtr", "net-tools", "rsync", "screen", "software-properties-common", "tmux", "tree", "unzip", "vim", "wget", "zip"]

    runcmd = ["/instance-init.sh"]
  }
}
