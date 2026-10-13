#!/bin/sh
case "$1" in
  deconfig)
    ip addr flush dev "$interface"
    ;;
  renew|bound)
    ip addr add "$ip/$mask" dev "$interface" 2>/dev/null
    ip route replace default via "$router" dev "$interface"
    ;;
esac
