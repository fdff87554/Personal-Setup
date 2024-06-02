#!/bin/bash

# Prepare the system
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y

# Install necessary packages
sudo apt-get install -y vim git curl wget certbot

# # Install Docker
# echo "Installing Docker..."
# curl -fsSL https://get.docker.com -o get-docker.sh
# sh get-docker.sh
# sudo usermod -aG docker "$USER"
# rm get-docker.sh

# Get Harbor release online version
HARBOR_VERSION="v2.9.4"
wget https://github.com/goharbor/harbor/releases/download/"$HARBOR_VERSION"/harbor-online-installer-"$HARBOR_VERSION".tgz
tar xzvf harbor-online-installer-"$HARBOR_VERSION".tgz

# Create letsencrypt certificate
sudo certbot certonly --standalone -d hub.hsnl.tw -v

# Modify harbor.yml
cd harbor || exit
cp harbor.yml.tmpl harbor.yml
# Please replace the following values with your own values
# sed -i 's/hostname: reg.mydomain.com/hostname: hub.hsnl.tw/g' harbor.yml
# sed -i 's/certificate: \/your\/certificate\/path/certificate: \/etc\/letsencrypt\/live\/hub.hsnl.tw\/fullchain.pem/g' harbor.yml
# sed -i 's/private_key: \/your\/private\/key\/path/private_key: \/etc\/letsencrypt\/live\/hub.hsnl.tw\/privkey.pem/g' harbor.yml
# sed -i 's/harbor_admin_password: Harbor12345/harbor_admin_password: hsnl33564/g' harbor.yml
# Add http: relativeurls: true to harbor.yml to fix the issue of retrying to push image
# password: hsnl33564 for database

# # Prepare the system
# ./prepare

# # Install Harbor
# sudo ./install.sh

/hostfs/etc/letsencrypt/live/hub.hsnl.tw/privkey.pem