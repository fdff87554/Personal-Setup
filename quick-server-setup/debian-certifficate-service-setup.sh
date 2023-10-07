#!/bin/sh

# Basic setup
# - Update & upgrade apt packages
echo "Updating apt packages..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

# - Install git, vim, curl, wget, tmux, ssh-server, apache2, openssl
echo "Installing git, vim, curl, wget, tmux, ssh-server, apache2, openssl..."
sudo apt install git vim curl wget tmux openssh-server apache2 openssl -y

