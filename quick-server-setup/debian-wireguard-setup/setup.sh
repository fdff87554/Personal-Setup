#!bin/bash

# Basic env setup
sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y
sudo apt-get install -y git vim curl sqlite3

# Docker Setup
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker "$USER"
rm get-docker.sh

# Install wireguard
echo "Install up wireguard..."
sudo apt-get install wireguard -y
# Get WireGuard Portal
echo "Cloning WireGuard Portal..."
git clone https://github.com/h44z/wg-portal.git

# Generate WireGuard Config
echo "Generating WireGuard Config..."
# - Generate WireGuard PrivateKey
wg genkey | sudo tee /etc/wireguard/private.key
# - Remove all permissions from the private key, except for the root user
sudo chmod go= /etc/wireguard/private.key

# - Generate WireGuard PublicKey by using the private key
sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key

# Prepare WireGuard Interface Config
echo "Preparing WireGuard Interface Config..."
# - Create /etc/wireguard/wg0.conf file if it doesn't exist
sudo touch /etc/wireguard/wg0.conf
echo "[Interface]
PrivateKey = $(sudo cat /etc/wireguard/private.key)
Address = 10.8.0.1/24
ListenPort = 12321
SaveConfig = true" | sudo tee /etc/wireguard/wg0.conf
# Set IP Forwarding for VPN (optional)
# - uncomment the #net.ipv4.ip_forward=1 line in /etc/sysctl.conf for IP forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
# - Add ip route in interface config
echo "PostUp = iptables -t nat -I POSTROUTING -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE" | sudo tee -a /etc/wireguard/wg0.conf

sudo systemctl start wg-quick@wg0.service
sudo systemctl enable wg-quick@wg0.service
# sudo systemctl status wg-quick@wg0.service
