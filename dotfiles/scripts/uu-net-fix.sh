#!/bin/bash
# 阻止 UU 插件劫持本机 DNS
LOG=/tmp/uu-net-fix.log
echo "[$(date)] uu-net-fix started" > "$LOG"
MARK=(-p udp --dport 53 -j MARK --set-xmark 0x164/0xffffffff)
while true; do
  # 1) 给本机所有 UDP/53 打 0x164 (mangle 早于 nat, 使插件 DNAT 不匹配)
  if ! iptables -t mangle -C OUTPUT "${MARK[@]}" >/dev/null 2>&1; then
    if iptables -t mangle -I OUTPUT 1 "${MARK[@]}" >/dev/null 2>&1; then
      echo "[$(date)] + DNS MARK 0x164" >> "$LOG"
    fi
  fi
  # 2) 删除插件对 127.0.0.1 tcp/53 的 DROP (最多试 8 次, 防死循环)
  for _ in 1 2 3 4 5 6 7 8; do
    spec=$(iptables -t mangle -S INPUT 2>/dev/null | grep -m1 -E '127\.0\.0\.1/32.*--dport 53.*-j DROP')
    [ -z "$spec" ] && break
    iptables -t mangle -D INPUT ${spec#-A INPUT } >/dev/null 2>&1 || break
    echo "[$(date)] - plugin tcp/53 DROP" >> "$LOG"
  done
  sleep 1
done
