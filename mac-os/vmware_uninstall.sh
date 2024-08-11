#!/bin/bash

# 函數：強制結束 VMware Fusion 進程
force_kill_vmware_fusion() {
  if pgrep "VMware Fusion" > /dev/null; then
    echo "正在強制結束 VMware Fusion..."
    sudo pkill -9 "VMware Fusion"
  fi
}

# 函數：解除安裝 VMware Fusion
uninstall_vmware_fusion() {
  if [ -d "/Applications/VMware Fusion.app" ]; then
    echo "正在移除 VMware Fusion 應用程式..."
    sudo mv "/Applications/VMware Fusion.app" ~/.Trash/
    sudo rm -rf ~/.Trash/VMware\ Fusion.app
  else
    echo "未找到 VMware Fusion 應用程式。"
  fi
}

# 函數：檢查並刪除檔案
delete_file() {
  if [ -e "$1" ]; then
    echo "正在刪除: $1"
    sudo rm -rf "$1"
  fi
}

# 主程序
echo "開始解除安裝 VMware Fusion..."

# 強制結束 VMware Fusion 進程
force_kill_vmware_fusion

# 解除安裝 VMware Fusion
uninstall_vmware_fusion

# 定義要刪除的檔案和目錄列表
files_to_delete=(
  "/Library/Application Support/VMware"
  "/Library/Preferences/VMware Fusion"
  "$HOME/Library/Application Support/VMware Fusion"
  "$HOME/Library/Caches/com.vmware.fusion"
  "$HOME/Library/Preferences/VMware Fusion"
  "$HOME/Library/Preferences/com.vmware.fusion.plist"
  "$HOME/Library/Preferences/com.vmware.fusionDaemon.plist"
  "$HOME/Library/Preferences/com.vmware.fusionStartMenu.plist"
)

# 遍歷列表並刪除檔案
for file_path in "${files_to_delete[@]}"; do
  delete_file "$file_path"
done

echo "清理和解除安裝已完成。"
echo "請注意，可能還有一些殘留檔案。如果您想徹底清除，請考慮重新啟動您的 Mac 並檢查是否有遺漏的檔案。"
