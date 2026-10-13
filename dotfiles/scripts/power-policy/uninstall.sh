#!/usr/bin/env bash
# 卸载 power-tune（需 root）： sudo bash ~/power-policy/uninstall.sh
set -eu
[ "$(id -u)" -eq 0 ] || { echo "请用 sudo 运行： sudo bash $0"; exit 1; }

systemctl disable --now power-tune.service 2>/dev/null || true
rm -f /etc/systemd/system/power-tune.service \
      /usr/local/sbin/power-tune \
      /etc/udev/rules.d/99-power-tune.rules
# 保留 /etc/default/power-tune 以便回滚；如需彻底删除：
#   sudo rm -f /etc/default/power-tune

systemctl daemon-reload
udevadm control --reload-rules

# 恢复系统默认
echo 1 | tee /proc/sys/kernel/nmi_watchdog >/dev/null 2>&1 || true
echo 60 | tee /proc/sys/vm/swappiness >/dev/null 2>&1 || true
echo 0 | tee /proc/sys/vm/laptop_mode >/dev/null 2>&1 || true
echo default | tee /sys/module/pcie_aspm/parameters/policy >/dev/null 2>&1 || true

echo "已卸载 power-tune ✅（/etc/default/power-tune 保留）"
