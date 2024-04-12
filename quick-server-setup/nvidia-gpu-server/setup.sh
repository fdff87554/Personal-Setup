#!/bin/sh

# 定義每個安裝階段的函數

# 第一階段：基礎環境設定
setup_basic_env() {
    echo "正在更新與升級apt套件..."
    sudo apt-get update && sudo apt-get -y full-upgrade && sudo apt-get -y autoremove

    echo "正在安裝 git, vim, curl, wget, tmux, openssh-server..."
    sudo apt-get install -y git vim curl wget tmux openssh-server

    echo "設定基本環境..."
    sudo systemctl enable ssh
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
    mkdir -p ~/.ssh
    touch ~/.ssh/authorized_keys
    sudo systemctl restart ssh

    echo "設定 vim..."
    curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/vim/.vimrc -o ~/.vimrc
    sudo curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/vim/.vimrc -o /root/.vimrc

    echo "設定 tmux..."
    curl -L https://raw.githubusercontent.com/fdff87554/Personal-Setup/main/tmux/.tmux.conf -o ~/.tmux.conf
    tmux source-file ~/.tmux.conf
}

# 第二階段：NVIDIA 驅動安裝
install_nvidia_driver() {
    if ! lspci | grep -iq nvidia; then
        echo "未發現 NVIDIA GPU，嘗試更新 PCI IDs..."
        sudo update-pciids
        if ! lspci | grep -iq nvidia; then
            echo "更新 PCI IDs 後仍未發現 NVIDIA GPU，退出..."
            exit 1
        fi
    fi

    if ! gcc --version >/dev/null 2>&1; then
        echo "未找到 gcc，正在安裝 build-essential..."
        sudo apt-get update
        sudo apt-get install -y build-essential
    fi

    sudo apt-get install -y linux-headers-$(uname -r)
    echo "正在安裝 NVIDIA 驅動..."
    sudo apt install -y ubuntu-drivers-common
    sudo ubuntu-drivers autoinstall

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

# 第三階段：CUDA 安裝 Toolkit / Container Toolkit 安裝
install_cuda_toolkit() {
    if ! nvidia-smi >/dev/null 2>&1; then
        echo "NVIDIA 驅動安裝失敗，退出..."
        exit 1
    fi

    echo "正在安裝 CUDA..."
    local ubuntu_version=$(lsb_release -rs)
    if [ "$ubuntu_version" = "20.04" ] || [ "$ubuntu_version" = "22.04" ]; then
        local distro=$(lsb_release -is | tr '[:upper:]' '[:lower:]')$(lsb_release -rs | tr -d '.')
        local arch=$(dpkg --print-architecture)
        if [ "$arch" = "amd64" ]; then
            arch="x86_64"
        fi

        echo "為 $distro 架構 $arch 添加 CUDA 儲存庫..."
        wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-keyring_1.1-1_all.deb
        sudo dpkg -i cuda-keyring_1.1-1_all.deb
        rm cuda-keyring_1.1-1_all.deb
        sudo apt-get update
    else
        echo "不支援的 Ubuntu 版本。請手動安裝 NVIDIA 驅動。"
        exit 1
    fi

    sudo apt-get install -y cuda-toolkit
    sudo apt-get install -y nvidia-gds

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

# 第四階段：Docker 安裝與後續設定
setup_docker_and_containers() {
    if ! cat /proc/driver/nvidia/version ; then
        echo "CUDA 安裝失敗，退出..."
        exit 1
    fi

    export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}

    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit

    echo "正在安裝 Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker "$USER"
    newgrp docker
    rm get-docker.sh

    echo "設定 NVIDIA 容器運行時..."
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker

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

# 主腳本執行邏輯
# 顯示選單並讀取用戶選擇
echo "請選擇執行階段："
echo "1. 第一階段（基礎環境設定）"
echo "2. 第二階段（NVIDIA 驅動安裝）"
echo "3. 第三階段（CUDA 安裝 Toolkit / Container Toolkit 安裝）"
echo "4. 第四階段（Docker 安裝與後續設定）"
read -p "請輸入選擇（1-4）：" stage

# 根據用戶選擇執行相應函數
case $stage in
1)
    setup_basic_env
    ;;
2)
    install_nvidia_driver
    ;;
3)
    install_cuda_toolkit
    ;;
4)
    setup_docker_and_containers
    ;;
*)
    echo "無效的選擇。請重新執行腳本並選擇1、2、3或4。"
    exit 1
    ;;
esac
