#!/usr/bin/env bash
# 系统修复脚本（需要 root）：sudo bash ~/fix-system.sh
# 只做以下几件安全、可逆的事，不会卸载/删除你的个人数据
set -u

echo "=============================================="
echo " 1/4  校正硬件时钟为 UTC"
echo "      （解决每次开机系统时间跳 8 小时）"
echo "=============================================="
hwclock --systohc --utc && echo "OK: 硬件时钟已写为 UTC"
timedatectl | grep -E "RTC time|Local time|synchronized"

echo
echo "=============================================="
echo " 2/4  清理崩溃报告"
echo "      （解决 update-notifier-crash 反复失败）"
echo "=============================================="
ls -la /var/crash/
rm -f /var/crash/*.crash
echo "OK: 已删除 /var/crash/*.crash，剩余："
ls -la /var/crash/

echo
echo "=============================================="
echo " 3/4  关闭未使用的 sssd 服务"
echo "      （sssd 无 sssd.conf 域配置，未被使用）"
echo "=============================================="
systemctl disable --now sssd.socket sssd-pam.socket 2>/dev/null
systemctl disable sssd.service 2>/dev/null
systemctl daemon-reload
echo "OK: 已禁用 sssd.socket / sssd-pam.socket / sssd.service"

echo
echo "=============================================="
echo " 4/4  重置失败的用户服务"
echo "=============================================="
sudo -u "${SUDO_USER:-$USER}" systemctl --user reset-failed 2>/dev/null || true
echo "OK"

echo
echo "全部完成 ✅  建议重启一次让输入法(fcitx5)与时钟完全生效。"
