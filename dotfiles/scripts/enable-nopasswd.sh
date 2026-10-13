#!/usr/bin/env bash
# 给用户 wyr 开启免密 sudo（需用 sudo 运行一次）
# 用法： sudo bash ~/enable-nopasswd.sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "请用 sudo 运行： sudo bash ~/enable-nopasswd.sh"
    exit 1
fi

USERNAME="wyr"
mkdir -p /etc/sudoers.d
echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/010-${USERNAME}-nopasswd
chmod 440 /etc/sudoers.d/010-${USERNAME}-nopasswd

echo "已写入: /etc/sudoers.d/010-${USERNAME}-nopasswd"
echo "内容: $(cat /etc/sudoers.d/010-${USERNAME}-nopasswd)"
echo
echo "语法检查:"
visudo -c
