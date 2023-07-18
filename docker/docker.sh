#!/bin/sh
# Get install script from docker and run it
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Create docker group and add current user into it
# sudo groupadd docker # Not need if install by docker script
sudo usermod -aG docker $USER
newgrp docker

# Check install result
docker run hello-world

# Remove install script
rm get-docker.sh
rm docker.sh
