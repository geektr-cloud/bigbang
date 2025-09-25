locals {
  keys_file = fileset(provider::tfproj::format("{secret.path}/public/keys"), "*.pub")
  keys_map = {
    for filename in local.keys_file : trimsuffix(filename, ".pub") => file(provider::tfproj::ensure("{secret.path}/public/keys/${filename}"))
  }
}

locals {
  closet_init_script = <<-EOSCRIPT
  #!/bin/bash -e

  apt-get update

  # =============== Docker ===============
  apt-get install -y ca-certificates curl gnupg

  install -m 0755 -d /etc/docker
  tee /etc/docker/daemon.json >/dev/null <<EOF
  {"registry-mirrors": ["https://dcr.oci.anitya.net"]}
  EOF

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://mirrors.anitya.net/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.anitya.net/docker-ce/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Install
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Chown
  chown terraform:terraform /srv

  # Clean
  rm /instance-init.sh
  EOSCRIPT
}

locals {
  closet_user_data = {
    # Storage
    disk_setup = {
      "/dev/vdb" = {
        table_type = "gpt"
        layout     = false
        overwrite  = true
      }
    }
    fs_setup = [{
      label      = "docker-data"
      filesystem = "ext4"
      device     = "/dev/vdb"
    }]
    mounts = [["/dev/vdb", "/var/lib/docker"]]

    # Network
    timezone                  = "Asia/Shanghai"
    hostname                  = "closet"
    fqdn                      = "closet.${local.infra.base_domain}"
    prefer_fqdn_over_hostname = true

    # Users
    ssh_pwauth = false
    ssh_authorized_keys = concat(
      [file(provider::tfproj::ensure("{secret.path}/terraform.pub"))],
      can(local.keys_map["root"]) ? [local.keys_map["root"]] : []
    )

    groups = ["docker"]

    users = concat(
      [{
        name                = "terraform"
        primary_group       = "terraform"
        shell               = "/bin/bash"
        groups              = ["sudo", "docker"]
        sudo                = "ALL=(ALL) NOPASSWD:ALL"
        lock_passwd         = true
        ssh_authorized_keys = [file(provider::tfproj::ensure("{secret.path}/terraform.pub"))]
      }],
      [for u, k in local.keys_map : {
        name                = u
        primary_group       = u
        shell               = "/bin/bash"
        groups              = ["sudo", "docker"]
        sudo                = "ALL=(ALL) NOPASSWD:ALL"
        lock_passwd         = true
        ssh_authorized_keys = [k]
      } if u != "root"]
    )

    write_files = [{
      path        = "/instance-init.sh"
      owner       = "root:root"
      permissions = "0700"
      content     = local.closet_init_script
    }]

    package_update  = true
    package_upgrade = true
    packages        = ["axel", "curl", "dnsutils", "git-lfs", "htop", "jq", "mtr", "net-tools", "rsync", "screen", "software-properties-common", "tmux", "tree", "unzip", "vim", "wget", "zip"]

    runcmd = ["/instance-init.sh"]
  }
}
