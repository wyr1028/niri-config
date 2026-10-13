#!/usr/bin/env bash
# =============================================================
#  安装 Visual Studio Code
#  用法：  bash ~/install-vscode.sh
#  优先用微软官方 apt 源（推荐）；失败则回退到 snap 版本
# =============================================================
set -u
export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -eq 0 ]; then
    echo "❌ 请不要用 root/sudo 运行，直接： bash ~/install-vscode.sh"
    exit 1
fi

echo "=============================================="
echo " 获取 sudo 权限（请输入登录密码）"
echo "=============================================="
sudo -n true 2>/dev/null || { echo "❌ 需要 sudo 权限（请先配置免密 sudo）。"; exit 1; }

ARCH="$(dpkg --print-architecture)"   # amd64
KEYRING="/usr/share/keyrings/microsoft.gpg"
LISTFILE="/etc/apt/sources.list.d/vscode.list"

echo
echo "====> 第 1 步：添加微软 GPG 密钥"
sudo apt-get install -y wget gpg apt-transport-https
if wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee "$KEYRING" >/dev/null; then
    echo "OK: 密钥已写入 $KEYRING"
else
    echo "⚠️  下载微软密钥失败（网络问题？）"
fi

echo
echo "====> 第 2 步：添加 VS Code 软件源"
echo "deb [arch=${ARCH} signed-by=${KEYRING}] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee "$LISTFILE" >/dev/null
echo "OK: 已写入 $LISTFILE"

echo
echo "====> 第 3 步：apt 安装 code"
if sudo apt-get update -qq && sudo apt-get install -y code; then
    echo
    echo "✅ VS Code 安装成功（apt 版）"
    echo "   命令：code .    /    应用列表里搜 “Visual Studio Code”"
    exit 0
fi

echo
echo "⚠️  apt 方式失败，回退到 snap 安装 ..."
if command -v snap >/dev/null 2>&1 && sudo snap install code --classic; then
    echo "✅ VS Code 安装成功（snap 版）"
    exit 0
fi

echo "❌ 两种方式都失败了，请把上面的报错发给我。"
exit 1
