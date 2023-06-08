#!/bin/sh
# Update apt package list
sudo apt update
sudo apt upgrade -y
sudo apt autoclean -y

# Install git, vim, curl, wget, tmux, ssh-server
sudo apt install git vim curl wget tmux openssh-server -y

# Setup ssh server
sudo systemctl enable ssh
# - Disable root login
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
# - Disable password login
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
# - Enable public key login
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
# - Add public key into authorized_keys
curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/ssh/id_rsa.pub -o ~/crazyfire_id_rsa.pub
cat ~/crazyfire_id_rsa.pub >> ~/.ssh/authorized_keys
rm ~/crazyfire_id_rsa.pub

sudo systemctl restart ssh

# Setup git if needed
curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/git/git.sh -o ~/git.sh
sh ~/git.sh

# Setup vim if needed
curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/vim/.vimrc -o ~/.vimrc

# Setup tmux if needed
curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/tmux/.tmux.conf -o ~/.tmux.conf
tmux source-file ~/.tmux.conf

# # If you want to setup docker, uncomment the following lines
# curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/docker/docker.sh -o ~/docker.sh
# sh ~/docker.sh
