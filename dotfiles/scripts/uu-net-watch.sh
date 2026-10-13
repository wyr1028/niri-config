#!/bin/bash
LOG=/tmp/uu-watch.log
: > "$LOG"
echo "[$(date)] 监控启动, 等待 UU 加速..." >> "$LOG"
prev=""
while true; do
  cur="$(ip rule; ip route show table all; ip -6 route show table all 2>/dev/null; \
         ip -br link; ip neigh; md5sum /etc/resolv.conf; resolvectl status 2>/dev/null; \
         iptables -t nat -S; iptables -t mangle -S; iptables -t filter -S; \
         ip6tables -t nat -S 2>/dev/null; ip6tables -t mangle -S 2>/dev/null; \
         sysctl net.ipv4.ip_forward net.ipv4.conf.all.proxy_arp 2>/dev/null; ipset list -n 2>/dev/null)"
  if [ "$cur" != "$prev" ]; then
    {
      echo ""
      echo "########## 变化 @ $(date) ##########"
      echo -n "  baidu: "; curl -s -o /dev/null -w '%{http_code} %{time_total}s\n' -m 5 https://www.baidu.com
      echo -n "  deepseek: "; curl -s -o /dev/null -w '%{http_code} %{time_total}s\n' -m 5 https://api.deepseek.com
      echo "--- ARP 邻居表 (网关 MAC 变成自己=ARP劫持) ---"; ip neigh
      echo "  本机 MAC: $(cat /sys/class/net/enp58s0/address)"
      /home/wyr/uu-net-snapshot.sh
    } >> "$LOG" 2>&1
    prev="$cur"
  fi
  sleep 2
done
