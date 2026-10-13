#!/bin/bash
# UU 加速器网络状态快照 —— 用于对比"加速前 / 加速后"
# 用法: ./uu-net-snapshot.sh  > /tmp/uu-before.txt   (加速前)
#       ./uu-net-snapshot.sh  > /tmp/uu-after.txt    (开启加速后)
#       diff -u /tmp/uu-before.txt /tmp/uu-after.txt
set -u

echo "########## TIME ##########"; date
echo; echo "########## IP RULE ##########"; ip rule
echo; echo "########## IP ROUTE (all tables) ##########"; ip route show table all
echo; echo "########## IP LINK ##########"; ip -br link
echo; echo "########## IP ADDR ##########"; ip -br addr
echo; echo "########## TUN / VPN DEV ##########"; ip -br link | grep -iE 'tun|tap|wg|utun' || echo "(none)"

echo; echo "########## IPTABLES FILTER ##########"; sudo iptables -t filter -S
echo; echo "########## IPTABLES NAT ##########";   sudo iptables -t nat -S
echo; echo "########## IPTABLES MANGLE ##########"; sudo iptables -t mangle -S
echo; echo "########## IP6TABLES NAT ##########";  sudo ip6tables -t nat -S 2>/dev/null
echo; echo "########## IP6TABLES MANGLE ##########"; sudo ip6tables -t mangle -S 2>/dev/null

echo; echo "########## NFT RULE SET ##########"; sudo nft list ruleset 2>/dev/null
echo; echo "########## IPSET LIST ##########"; sudo ipset list 2>/dev/null || echo "(no ipset)"

echo; echo "########## /etc/resolv.conf ##########"; cat /etc/resolv.conf
echo; echo "########## RESOLVECTL ##########"; resolvectl status 2>/dev/null

echo; echo "########## LISTEN PORTS ##########"; sudo ss -tulnp
echo; echo "########## UU PROCS ##########"; ps aux | grep -iE 'uuplugin|xuplugin|/opt/uu' | grep -v grep
echo; echo "########## CGROUP xuplugin-steam-deck procs ##########"; cat /sys/fs/cgroup/xuplugin-steam-deck/cgroup.procs 2>/dev/null || echo "(none)"
echo; echo "########## UU CGROUP TREE ##########"; find /sys/fs/cgroup -maxdepth 2 -iname '*uu*' 2>/dev/null
