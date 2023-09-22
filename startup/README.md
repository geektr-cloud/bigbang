# Startup

## 1. Init encrypt drive

```sh
# install veracrypt
pushd /tmp
wget https://launchpad.net/veracrypt/trunk/1.25.9/+download/veracrypt-console-1.25.9-Debian-11-amd64.deb
# echo "3bced524b78da981032541aa5faac98c1f4d07589770d75470bbd355493ed06667cb182c4323a757678ceada8253778a64b8dbda27750ba701fbd54cb65b3ec1  veracrypt-console-1.25.9-Debian-11-amd64.deb" | shasum -a256 -c
sudo apt install ./veracrypt-console-1.25.9-Debian-11-amd64.deb
rm ./veracrypt-console-1.25.9-Debian-11-amd64.deb
popd

# mkdir .secret mountpoint
mkdir .secret

# create container
veracrypt --create secret.hc --size=10MiB --volume-type=normal --encryption=aes --hash=sha-256 --filesystem=ext4 --pim=1453 --keyfiles="" --random-source /dev/random

# mount container
veracrypt --mount secret.hc ./.secret --pim=1453 --keyfiles="" --volume-type=normal --protect-hidden=no
sudo chown "$USER:$USER" secret

# unmount container
veracrypt -d secret.hc

# backup container
mkdir -p /mnt/geektr-secret/VeraCrypt/github.com/geektr-cloud/bigbang
cp secret.hc /mnt/geektr-secret/VeraCrypt/github.com/geektr-cloud/bigbang/secret-$(date '+%Y%m%d-%H%M%S').hc
```

## 2. Init secret files

```sh
# create files
touch .secret/1password.tfvars
touch .secret/alicloud.tfvars

# link files
cd startup
ln -s ../.secret/1password.tfvars ./1password.auto.tfvars
ln -s ../.secret/alicloud.tfvars ./alicloud.auto.tfvars
```

## 3. Install 1password-cli

[Official Document](https://developer.1password.com/docs/cli/get-started/#install)

```sh
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
 sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" |
 sudo tee /etc/apt/sources.list.d/1password.list

sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
 sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
 sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

sudo apt update && sudo apt install 1password-cli
op --version
```
