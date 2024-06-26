#!/bin/sh

# Update the system
echo "Updating apt packages..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

# Install need packages, and install docker
echo "Installing git, vim, curl, wget, tmux, ssh-server..."
sudo apt install -y git vim curl wget tmux openssh-server

# Setup ssh server
echo "Setting up ssh server..."
sudo systemctl enable ssh
# - Disable root login
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
# - Disable password login
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
# - Enable public key login
sudo sed -i 's/#PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
# - Add public key into authorized_keys
curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/ssh/id_rsa.pub -o ~/crazyfire_id_rsa.pub
# - Create .ssh folder if not exist
mkdir ~/.ssh
touch ~/.ssh/authorized_keys
cat ~/crazyfire_id_rsa.pub >>~/.ssh/authorized_keys
rm ~/crazyfire_id_rsa.pub

sudo systemctl restart ssh

# Setup git if needed
echo "Setting up git..."
curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/git/git.sh -o ~/git.sh
sh ~/git.sh
rm ~/git.sh

# Setup vim if needed
echo "Setting up vim..."
curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/vim/.vimrc -o ~/.vimrc
sudo curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/vim/.vimrc -o /root/.vimrc

# Setup tmux if needed
echo "Setting up tmux..."
curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/tmux/.tmux.conf -o ~/.tmux.conf
tmux source-file ~/.tmux.conf

# Setup docker
echo "Setting up docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker "$USER"
newgrp docker
rm get-docker.sh

# Setup Static IP
echo "Setting up static IP ..."
# - Prepare Backup
sudo cp /etc/network/interfaces /etc/network/interfaces.dhcp.bk
# - Change interfaces file
sudo sed -i 's/allow-hotplug ens18/auto ens18/g' /etc/network/interfaces
sudo sed -i 's/iface ens18 inet dhcp/iface ens18 inet static/g' /etc/network/interfaces
printf "\naddress 192.168.50.240" | sudo tee -a /etc/network/interfaces
printf "\nnetmask 255.255.255.0" | sudo tee -a /etc/network/interfaces
printf "\ngateway 192.168.50.254" | sudo tee -a /etc/network/interfaces
printf "\ndns-nameservers 192.168.51.53" | sudo tee -a /etc/network/interfaces

# Get Docker Compose files
echo "Getting docker-compose files..."
mkdir apps
cd apps || exit
curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/quick-server-setup/self-host-apps/compose.yml -o ./compose.yml
curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/quick-server-setup/self-host-apps/example.env -o ./.env
mkdir shlink
curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/quick-server-setup/self-host-apps/servers.json -o ./shlink/servers.json

# Wait for 1 minute for the env settings
echo "Waiting for 1 minute for the env settings..."
sleep 60
echo "Starting docker-compose..."

docker compose up -d

cd ~ || exit

# Wait for 1 minute for the apps to start
echo "Waiting for 1 minute for the apps to start..."
sleep 60

# Setup Nginx and Certbot
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

# - Setup Nginx
sudo curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/quick-server-setup/self-host-apps/services.conf -o /etc/nginx/sites-available/services.conf
sudo ln -s /etc/nginx/sites-available/services.conf /etc/nginx/sites-enabled/
sudo nginx -t

sudo systemctl reload nginx.service

# - Get SSL certificate
sudo certbot --nginx -d links.crazyfirelee.tw
sudo certbot --nginx -d qrcode.crazyfirelee.tw
sudo certbot --nginx -d cyberchef.crazyfirelee.tw
