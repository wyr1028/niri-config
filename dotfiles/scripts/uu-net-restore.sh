#!/bin/bash
# UU 加速器"车祸现场"急救脚本 —— 清理它留下的全局劫持，恢复本机正常上网
# 用法: sudo ./uu-net-restore.sh           # 只诊断+提示，不改动
#       sudo ./uu-net-restore.sh --apply   # 真正清理
set -u
APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

run() { echo "  + $*"; [ "$APPLY" = 1 ] && eval "$@"; }

echo "=== [1] 停止 UU 插件服务(它会自行清理大部分规则) ==="
run "systemctl stop uud.service 2>/dev/null; systemctl stop uud.timer 2>/dev/null"

echo "=== [2] 删除 UU 的 fwmark(0x164) 策略路由 ==="
while ip rule show | grep -qE 'fwmark (0x164|356)'; do
  line=$(ip rule show | grep -E 'fwmark (0x164|356)' | head -1)
  prio=$(echo "$line" | awk -F: '{print $1}' | tr -d ' ')
  echo "  删除 rule prio=$prio : $line"
  run "ip rule del prio $prio 2>/dev/null"
done

echo "=== [3] 删除 tun0 虚拟网卡 ==="
run "ip link del tun0 2>/dev/null || true"

echo "=== [4] 删除 UU 的 mangle MARK 规则 ==="
run "iptables -t mangle -D OUTPUT -m cgroup --path xuplugin-steam-deck -j MARK --set-xmark 0x164/0xffffffff 2>/dev/null || true"

echo "=== [5] 清理 UU 的 DNAT/ipset (nat 表里指向本地 dnat 服务器的规则) ==="
# 只删除带 ipset 或 uu/dnat 标识的 nat 规则，避免误伤 docker
run "iptables -t nat -S | grep -iE 'uu|dnat|ipset' | sed 's/^-A/iptables -t nat -D/' | sed 's/^/  /'"
if [ "$APPLY" = 1 ]; then
  iptables -t nat -S | grep -iE 'uu|dnat|ipset' | sed 's/^-A/iptables -t nat -D/' | while read -r c; do eval "$c" 2>/dev/null; done
fi
for s in $(ipset list -n 2>/dev/null | grep -iE 'uu|dnat|tproxy'); do
  run "ipset destroy $s 2>/dev/null"
done

echo "=== [6] 恢复 DNS (systemd-resolved, DHCP 自动下发) ==="
run "resolvectl flush-caches"
run "resolvectl domain enp58s0 '~.' 2>/dev/null || true"

echo
echo "=== 当前状态 ==="
ip rule show
ip route show
echo "resolv:"; resolvectl status 2>/dev/null | grep -A3 'Link 2' || true

if [ "$APPLY" = 0 ]; then
  echo
  echo ">>> 以上只是预览。确认没问题后执行:  sudo $0 --apply"
fi
