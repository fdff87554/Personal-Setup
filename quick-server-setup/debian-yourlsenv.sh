#!/bin/sh

# Export command from sbin to path in .bashrc
echo "Exporting command from sbin to path in .bashrc..."
echo "export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin" >>~/.bashrc
export PATH=$PATH:/usr/sbin

# Basic setup for a Debian server running YOURLS
echo "Basic setup for a Debian server running YOURLS"

# Update the system
echo "Updating apt packages..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

# Install need packages, and install docker
echo "Installing git, vim, curl, wget, tmux, ssh-server..."
sudo apt install -y git vim curl wget tmux openssh-server snapd

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
if [ ! -d ~/.ssh ]; then
    mkdir ~/.ssh
    touch ~/.ssh/authorized_keys
fi
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
sudo usermod -aG docker $USER
newgrp docker
rm get-docker.sh

# Install Certbot
echo "Installing certbot..."
# - Install snapd
sudo apt install snapd -y
# - Install certbot
sudo snap install --classic certbot
# - Prepare the Certbot command
sudo ln -s /snap/bin/certbot /usr/bin/certbot
