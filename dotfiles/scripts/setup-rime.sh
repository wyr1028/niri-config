#!/usr/bin/env bash
# 安装 ibus-rime 并切换到「雾凇拼音」
# 用法：bash ~/setup-rime.sh      （安装时需要输入你的登录密码）
set -u

RIME_DIR="$HOME/.config/ibus/rime"

echo "=============================================="
echo " [1/3] 安装 ibus-rime（请输入登录密码）"
echo "=============================================="
sudo apt-get update -qq
if ! sudo apt-get install -y ibus-rime; then
    echo "❌ 安装失败，脚本中止。"
    exit 1
fi

echo
echo "=============================================="
echo " [2/3] 设置 GNOME 输入源为 英文 + Rime"
echo "=============================================="
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'rime')]"
echo "当前输入源: $(gsettings get org.gnome.desktop.input-sources sources)"

echo
echo "=============================================="
echo " [3/3] 重启 ibus 并部署雾凇拼音（首次编译需几秒）"
echo "=============================================="
ibus restart 2>/dev/null || true
sleep 5

echo
echo "词库目录: $RIME_DIR"
if [ -d "$RIME_DIR/build" ] && [ -n "$(ls -A "$RIME_DIR/build" 2>/dev/null)" ]; then
    echo "✅ 部署已完成（build 目录已生成）"
else
    echo "ℹ️ 首次部署可能仍在进行，若方案不是「雾凇拼音」，"
    echo "   请运行: ibus restart   或注销后重新登录"
fi

echo
echo "全部完成 ✅"
echo "切换输入法：Super+Space（Windows 键 + 空格）或 Ctrl+Space"
echo "默认方案：雾凇拼音（全拼）；支持简繁、emoji、日期、符号等。"
