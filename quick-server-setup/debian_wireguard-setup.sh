#!/bin/sh

# Update & upgrade apt packages
echo "Updating apt packages..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

# Install git, vim, curl, wget, tmux, ssh-server
echo "Installing git, vim, curl, wget, tmux, ssh-server..."
sudo apt install git vim curl wget tmux openssh-server -y

# Setup ssh server
echo "Setting up ssh server..."
sudo systemctl start ssh
sudo systemctl enable ssh
# - Disable root login
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
# - Disable password login
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
# - Enable public key login
sudo sed -i 's/#PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
# - Add public key into authorized_keys
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
curl -L https://link.crazyfirelee.tw/ssh-key -o ~/crazyfire_id_rsa.pub
cat ~/crazyfire_id_rsa.pub >> ~/.ssh/authorized_keys
rm ~/crazyfire_id_rsa.pub

sudo systemctl restart ssh

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
sudo usermod -aG docker $USER
newgrp docker
rm get-docker.sh

# Setup wireguard
echo "Setting up wireguard..."
# - Install wireguard
sudo apt install wireguard -y
# - Get WireGuard Portal
git clone https://github.com/h44z/wg-portal.git
