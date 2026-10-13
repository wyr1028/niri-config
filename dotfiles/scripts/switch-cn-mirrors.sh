#!/usr/bin/env bash
# =============================================================
#  把系统级软件源切换为国内镜像（需要 sudo）
#  用法：  bash ~/switch-cn-mirrors.sh
#  内容：  apt  -> 清华 TUNA
#          flatpak -> 中科大 USTC 的 flathub 镜像
#          docker  -> 若已安装则加国内 registry 镜像
#  所有改动都会先备份，可回滚
# =============================================================
set -u
export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -eq 0 ]; then
    echo "❌ 请不要用 root/sudo 运行，直接： bash ~/switch-cn-mirrors.sh"
    exit 1
fi
sudo -n true 2>/dev/null || { echo "❌ 需要 sudo 权限（请先配置免密 sudo）。"; exit 1; }

STAMP="$(date +%Y%m%d-%H%M%S)"

echo "=============================================="
echo " [1/3] apt 源 -> 清华 TUNA"
echo "=============================================="
SRC="/etc/apt/sources.list.d/ubuntu.sources"
sudo cp -a "$SRC" "${SRC}.bak-${STAMP}"
echo "已备份: ${SRC}.bak-${STAMP}"

sudo tee "$SRC" >/dev/null <<'EOF'
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu/
Suites: resolute resolute-updates resolute-backports resolute-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
echo "已写入清华源。"
echo "刷新缓存..."
if sudo apt-get update; then
    echo "OK: apt 源切换成功"
else
    echo "⚠️  apt update 出错，正在回滚到切换前的源..."
    sudo cp -a "${SRC}.bak-${STAMP}" "$SRC"
    sudo apt-get update
    echo "已回滚。"
    exit 1
fi

echo
echo "=============================================="
echo " [2/3] flatpak flathub -> 中科大 USTC 镜像"
echo "=============================================="
FLATHUB_URL="https://mirror.sjtu.edu.cn/flathub/flathub.flatpakrepo"
if flatpak remote-list 2>/dev/null | grep -q '^flathub'; then
    echo "flathub 已存在，直接改指向镜像"
else
    flatpak remote-add --if-not-exists flathub "$FLATHUB_URL"
fi
flatpak remote-modify flathub --url=https://mirror.sjtu.edu.cn/flathub \
    && echo "OK: flathub 已指向 SJTU 镜像"
echo "当前 remotes:"; flatpak remotes -d

echo
echo "=============================================="
echo " [3/3] docker registry 镜像（仅在已安装 docker 时）"
echo "=============================================="
if command -v docker >/dev/null 2>&1; then
    sudo mkdir -p /etc/docker
    if [ -f /etc/docker/daemon.json ]; then
        sudo cp -a /etc/docker/daemon.json "/etc/docker/daemon.json.bak-${STAMP}"
    fi
    sudo tee /etc/docker/daemon.json >/dev/null <<'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://hub-mirror.c.163.com"
  ]
}
EOF
    sudo systemctl restart docker 2>/dev/null && echo "OK: 已配置 docker registry 镜像并重启"
else
    echo "ℹ️  未安装 docker，跳过（以后装了 docker 可再跑一次本脚本）。"
fi

echo
echo "全部完成 ✅"
echo "回滚 apt 源:  sudo cp ${SRC}.bak-${STAMP} ${SRC} && sudo apt update"
