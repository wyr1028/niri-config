#!/usr/bin/env bash
# 安装 power-tune（需 root）： sudo bash ~/power-policy/install.sh
set -eu

[ "$(id -u)" -eq 0 ] || { echo "请用 sudo 运行： sudo bash $0"; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)"

echo "==> 安装文件"
install -m 0755 "$SRC/power-tune"            /usr/local/sbin/power-tune
install -m 0644 "$SRC/power-tune.service"    /etc/systemd/system/power-tune.service
install -m 0644 "$SRC/99-power-tune.rules"   /etc/udev/rules.d/99-power-tune.rules

# 配置只在不存在时写入，避免覆盖你的自定义
if [ -e /etc/default/power-tune ]; then
    echo "==> /etc/default/power-tune 已存在，保留现有配置"
else
    install -m 0644 "$SRC/power-tune.conf" /etc/default/power-tune
    echo "==> 写入默认配置 /etc/default/power-tune"
fi

echo "==> 重载 systemd / udev"
systemctl daemon-reload
systemctl enable power-tune.service >/dev/null
udevadm control --reload-rules

echo "==> 立即应用一次"
/usr/local/sbin/power-tune

echo
echo "==> 当前状态"
echo -n "AC在线: "; cat /sys/class/power_supply/AC0/online 2>/dev/null || echo "?"
echo -n "当前文件: "; powerprofilesctl get 2>/dev/null || echo "?"
echo -n "ASPM: "; cat /sys/module/pcie_aspm/parameters/policy 2>/dev/null
echo -n "swappiness: "; sysctl -n vm.swappiness
echo
echo "安装完成 ✅  插拔电源时会自动切换。"
echo "改配置: sudoedit /etc/default/power-tune && sudo /usr/local/sbin/power-tune"
