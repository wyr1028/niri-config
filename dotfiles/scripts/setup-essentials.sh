#!/usr/bin/env bash
# =============================================================
#  Ubuntu 26.04 必备软件安装脚本（笔记本 / Intel + NVIDIA）
#  用法：  bash ~/setup-essentials.sh
#  说明：  脚本内部会调用 sudo（会提示输入你的登录密码）
#          * 卸载 fcitx5，统一使用 ibus-rime
#          * 分批安装常用软件，单组失败不影响其它组
#          * 结束后生成 ~/installed-report.txt（本次新增的包）
# =============================================================
set -u

REPORT="$HOME/installed-report.txt"
export DEBIAN_FRONTEND=noninteractive

# ---- 不能用 root 跑（否则用户级配置会写到 root） ----
if [ "$(id -u)" -eq 0 ]; then
    echo "❌ 请不要用 root/sudo 运行本脚本。"
    echo "   正确用法： bash ~/setup-essentials.sh"
    exit 1
fi

echo "=============================================="
echo " 检查 sudo 权限"
echo "=============================================="
sudo -n true 2>/dev/null || { echo "❌ 需要 sudo 权限（请先配置免密 sudo）。"; exit 1; }

# ---- 记录安装前的包列表，用于最终 diff ----
echo "正在记录当前已安装包（用于生成报告）..."
dpkg-query -W -f='${Package}\n' 2>/dev/null | sort > /tmp/pkgs_before.txt

echo
echo "=============================================="
echo " [1/4] 更新软件源"
echo "=============================================="
sudo apt-get update -qq

echo
echo "=============================================="
echo " [2/4] 卸载 fcitx5，统一到 ibus-rime"
echo "=============================================="
FCITX_PKGS="fcitx5 fcitx5-chinese-addons fcitx5-chinese-addons-bin fcitx5-chinese-addons-data fcitx5-config-qt fcitx5-data fcitx5-frontend-all fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5 fcitx5-frontend-qt6 fcitx5-module-chttrans fcitx5-module-cloudpinyin fcitx5-module-fullwidth fcitx5-module-lua fcitx5-module-lua-common fcitx5-module-pinyinhelper fcitx5-module-punctuation fcitx5-modules fcitx5-pinyin fcitx5-pinyin-gui fcitx5-table libfcitx5-qt-data libfcitx5-qt1 libfcitx5-qt6-1 libfcitx5config6 libfcitx5core7 libfcitx5gclient2 libfcitx5utils2"
# shellcheck disable=SC2086
sudo apt-get purge -y $FCITX_PKGS || echo "ℹ️  部分 fcitx5 包可能已被移除，继续。"
sudo apt-get autoremove --purge -y

# 备份 fcitx5 用户配置（不删除，方便以后想用）
[ -d "$HOME/.config/fcitx5" ] && mv "$HOME/.config/fcitx5" "$HOME/.config/fcitx5.disabled" && echo "已把 ~/.config/fcitx5 备份为 ~/.config/fcitx5.disabled"
[ -d "$HOME/.local/share/fcitx5" ] && mv "$HOME/.local/share/fcitx5" "$HOME/.local/share/fcitx5.disabled" 2>/dev/null

# 确保 ibus-rime 存在并设为默认输入法
sudo apt-get install -y ibus ibus-rime
im-config -n ibus >/dev/null 2>&1 && echo "OK: im-config 已设为 ibus"
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'rime')]" 2>/dev/null && \
    echo "OK: GNOME 输入源 = 英文 + Rime"

# 在 ~/.profile 中补上 ibus 环境变量（若缺失）
if ! grep -q "QT_IM_MODULE=ibus" "$HOME/.profile" 2>/dev/null; then
    cat >> "$HOME/.profile" <<'EOF'

# ---- 输入法：ibus ----
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
EOF
    echo "OK: 已写入 ibus 环境变量到 ~/.profile"
fi

echo
echo "=============================================="
echo " [3/4] 安装常用软件（分组，失败不影响其它组）"
echo "=============================================="
OK_GROUPS=(); FAIL_GROUPS=()

install_group () {
    local name="$1"; shift
    echo
    echo "----> [$name] $*"
    if sudo apt-get install -y "$@"; then
        OK_GROUPS+=("$name")
    else
        echo "⚠️  分组 [$name] 安装失败，已跳过。"
        FAIL_GROUPS+=("$name")
    fi
}

# 某些包（ubuntu-restricted-extras）会问微软字体 EULA，预先接受以免卡住
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections 2>/dev/null || true

install_group "系统维护" \
    timeshift gparted gdebi synaptic software-properties-gtk \
    flatpak gnome-software-plugin-flatpak gufw \
    7zip unrar ubuntu-restricted-extras

install_group "终端效率" \
    htop btop tree ripgrep bat fzf tmux zsh neovim \
    ncdu eza fastfetch git-lfs

# 注意：不装 tlp —— 保留系统自带的 power-profiles-daemon，避免两者争抢电源策略
install_group "笔记本省电" \
    powertop thermald zram-tools

install_group "图形多媒体" \
    ffmpeg mpv vlc gimp obs-studio flameshot qbittorrent aria2

install_group "开发网络" \
    docker.io docker-compose-v2 python3-pip pipx \
    bind9-dnsutils net-tools nmap socat iftop iotop sysstat traceroute

install_group "手机远程" \
    scrcpy adb remmina filezilla

# 把当前用户加入 docker 组（重新登录后生效）
if getent group docker >/dev/null; then
    sudo usermod -aG docker "$USER" && echo "OK: 已把 $USER 加入 docker 组（重新登录后免 sudo）"
fi

echo
echo "=============================================="
echo " [4/4] 清理并生成安装报告"
echo "=============================================="
sudo apt-get autoremove -y

dpkg-query -W -f='${Package}\n' 2>/dev/null | sort > /tmp/pkgs_after.txt
comm -13 /tmp/pkgs_before.txt /tmp/pkgs_after.txt > "$REPORT"

echo
echo "成功分组: ${OK_GROUPS[*]:-无}"
[ "${#FAIL_GROUPS[@]}" -gt 0 ] && echo "失败分组: ${FAIL_GROUPS[*]}"

echo
echo "本次新增安装的包（共 $(wc -l < "$REPORT") 个）已写入: $REPORT"
echo "查看:  cat $REPORT"

# 重启 ibus 让 Rime 立即生效
ibus restart >/dev/null 2>&1 || true

echo
echo "全部完成 ✅"
echo "⚠️  请注销/重启一次，让 fcitx5 完全消失、docker 组和 ibus 环境生效。"
