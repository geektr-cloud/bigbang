#!/usr/bin/env bash

tfssh() { ssh -F /home/geektr/projects/github.com/geektr-cloud/bigbang/.secret/store/cloud-infra-secrets/ssh_config "$@"; }
tfsync() { rsync -avz -e 'ssh -F /home/geektr/projects/github.com/geektr-cloud/bigbang/.secret/store/cloud-infra-secrets/ssh_config' "$@"; }

tfsync --delete compose/ closet.geektr.co:/srv/closet
tfsync /home/geektr/projects/github.com/geektr-cloud/bigbang/.secret/store/cloud-infra-secrets/secrets.env closet.geektr.co:/srv/closet/secrets.env

tfssh closet.geektr.co "cd /srv/closet && docker compose --env-file secrets.env up -d"
