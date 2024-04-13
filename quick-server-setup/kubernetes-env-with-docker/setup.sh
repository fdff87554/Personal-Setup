#!/bin/sh
#  This install is base on ref:
#  - https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-runtime
#  - https://blog.jks.coffee/on-premise-self-host-kubernetes-k8s-setup/

# Define basic environment parameters
K9S_VERSION=
SUPPORT_K8S_VERSION="1.29"
K8S_VERSION=1.29

setup_basic_env() {
    # Basic Environment Setup
    echo "Updating and upgrading apt packages..."
    sudo apt-get update && sudo apt-get -y full-upgrade && sudo apt-get -y autoremove

    echo "Installing git, vim, curl, wget, tmux, openssh-server, netcat..."
    sudo apt-get install -y git vim curl wget tmux openssh-server netcat-openbsd

    echo "Setting up basic environment..."

    echo "For ssh settings..."
    sudo systemctl enable ssh
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
    mkdir -p ~/.ssh
    touch ~/.ssh/authorized_keys
    sudo systemctl restart ssh
    curl -L https://link.crazyfirelee.tw/ssh-key -o ~/crazyfire_id_rsa.pub
    cat ~/crazyfire_id_rsa.pub >>~/.ssh/authorized_keys
    rm ~/crazyfire_id_rsa.pub

    echo "Setting up vim..."
    curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/vim/.vimrc -o ~/.vimrc
    sudo curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/vim/.vimrc -o /root/.vimrc

    echo "Setting up tmux..."
    curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/tmux/.tmux.conf -o ~/.tmux.conf
    tmux source-file ~/.tmux.conf

    echo "設置完成。請重啟系統以套用所有更改。"
    echo "是否現在重啟？(y/n)"
    read -r answer
    if [ "$answer" = "y" ]; then
        echo "正在重啟..."
        sudo reboot
    else
        echo "請手動重啟系統以完成設置。"
    fi
}

preinstall_check() {
    # Get mac address
    MAC_ADDRESS=$(ip link show | grep "link/ether" | awk '{print $2}' | head -n 1)
    # Check product_uuid
    PRODUCT_UUID=$(sudo cat /sys/class/dmi/id/product_uuid)

    echo "MAC Address: $MAC_ADDRESS"
    echo "Product UUID: $PRODUCT_UUID"
    # Change hostname to control or worker node
    echo "Please enter the hostname for this node (control or worker):"
    read -r HOSTNAME
    echo "Setting up hostname..."
    sudo hostnamectl set-hostname "$HOSTNAME"
}

setup_docker_env() {
    # Docker Setup
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker "$USER"
    rm get-docker.sh

    # Setup cri-dockerd
    echo "Installing cri-dockerd..."
    curl -L https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.12/cri-dockerd_0.3.12.3-0.ubuntu-jammy_amd64.deb -o cri-dockerd_0.3.12.3-0.ubuntu-jammy_amd64.deb
    sudo dpkg -i cri-dockerd_0.3.12.3-0.ubuntu-jammy_amd64.deb
    sudo systemctl daemon-reload
    sudo systemctl enable cri-docker.service
    sudo systemctl start cri-docker.service

    rm -f cri-dockerd_0.3.12.3-0.ubuntu-jammy_amd64.deb

    echo "設置完成。請重啟系統以套用所有更改。"
    echo "是否現在重啟？(y/n)"
    read -r answer
    if [ "$answer" = "y" ]; then
        echo "正在重啟..."
        sudo reboot
    else
        echo "請在結束此會話後重啟系統以完成設置。"
    fi
}

setup_k8s_env() {
    if [ -z "$K8S_VERSION" ]; then
        echo "K8S_VERSION is not set. Please export K8S_VERSION with the desired Kubernetes version."
        exit 1
    fi

    echo "Setting up base environment for Kubernetes"
    sudo sysctl -w vm.swappiness=0
    if [ "$(swapon --show | wc -l)" -gt 0 ]; then
        sudo swapoff -a
    fi
    sudo sed -i '/[[:space:]]swap[[:space:]]/ s/^/#/' /etc/fstab

    echo "Installing base apt packages..."
    sudo apt-get install -y apt-transport-https ca-certificates curl gpg || {
        echo "Failed to install base packages"
        exit 1
    }
    if [ ! -d "/etc/apt/keyrings" ]; then
        sudo mkdir -p /etc/apt/keyrings
    fi
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo "Adding Kubernetes repository..."
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    echo "Installing kubeadm, kubelet, kubectl..."
    sudo apt-get update
    sudo apt-get install -y kubeadm kubelet kubectl || {
        echo "Failed to install Kubernetes components"
        exit 1
    }
    sudo apt-mark hold kubelet kubeadm kubectl
    sudo systemctl enable --now kubelet

    echo "Setting cgroup modules..."
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

    sudo modprobe overlay
    sudo modprobe br_netfilter

    echo "Applying sysctl params required by setup..."
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

    sudo sysctl --system

    echo "Check all versions..."
    kubectl version
    kubeadm version
    kubelet --version
}

k8s_init_check() {
    # Cehck docker cgroup driver as systemd
    if [ "$(docker info | grep "Cgroup Driver" | awk '{print $3}')" != "systemd" ]; then
        echo "Docker cgroup driver is not set to systemd. Please set it to systemd and restart docker."

        echo "Setting up docker cgroup driver..."
        # check if directory exists
        if [ ! -d "/etc/docker" ]; then
            sudo mkdir -p /etc/docker
        fi
        cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    },
    "storage-driver": "overlay2"
}
EOF
        sudo systemctl restart docker
    fi

    # # Check if cgroup driver of kubelet is systemd
    # # check if config file /var/lib/ exists
    # if [ ! -f "/etc/default/kubelet" ]; then
    #     echo "Kubelet config file does not exist. Please create /etc/default/kubelet and set KUBELET_EXTRA_ARGS=--cgroup-driver=systemd"
    #     exit 1
    # fi
}

k8s_init() {
    # Initialize Kubernetes
    echo "Initializing Kubernetes..."
    sudo kubeadm init \
        --node-name=control-node \
        --pod-network-cidr=10.244.0.0/16 \
        --cri-socket='unix:///var/run/cri-dockerd.sock'

    # Setup kubectl
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    export KUBECONFIG=/etc/kubernetes/admin.conf

    # If you forget the join command, you can run the following command to get the join command
    # kubeadm token create --print-join-command

    # Prepare Helm tools
    echo "Preparing Helm tools..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh

    # Install Flannel CNI
    echo "Installing Flannel CNI..."
    # Needs manual creation of namespace to avoid helm error
    kubectl create ns kube-flannel
    kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged

    helm repo add flannel https://flannel-io.github.io/flannel/
    helm install flannel --set podCidr="10.244.0.0/16" --namespace kube-flannel flannel/flannel
}

# # Join the worker node to the cluster
# kubeadm join <control-plane-host>:<control-plane-port> \
#  --token <token> \
#  --discovery-token-ca-cert-hash sha256:<hash> \
#  --cri-socket='unix:///var/run/cri-dockerd.sock'
# 
# # Restart coredns for a better DNS resolution
# kubectl -n kube-system rollout restart deployment coredns

# Main script
echo "Please select the environment you want to set up:"
echo "1. Basic Environment Setup"
echo "2. Docker Environment Setup"
echo "3. Kubernetes Environment Setup"
echo "4. Pre-installation Check"
echo "5. Kubernetes Initialization Check"
read -r ENV

case $ENV in
1)
    setup_basic_env
    ;;
2)
    setup_docker_env
    ;;
3)
    setup_k8s_env
    ;;
4)
    preinstall_check
    ;;
5)
    k8s_init_check
    ;;
*)
    echo "Invalid option. Please select a valid option."
    ;;
esac
