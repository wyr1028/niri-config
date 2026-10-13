# MECHREVO GM6IX8B 电源策略优化（power-tune）

适配机型：MECHREVO 曜石16Super `GM6IX8B` / i9-14900HX / RTX 4080 Laptop / Ubuntu 26.04

## 它做了什么

保留系统自带的 `power-profiles-daemon`（PPD）负责 CPU，本方案补上 PPD 缺失的
**AC/电池自动切换 + 外设/内核省电项**，插拔电源时由 udev 自动触发。

| 项目 | 插电 (AC) | 电池 (BAT) |
|---|---|---|
| PPD 配置 | `performance` | `power-saver` |
| PCIe ASPM | `default`（稳定/性能） | `powersave`（省电） |
| WiFi 省电 | 关 | 开 |
| nmi_watchdog | 开 | 关 |
| vm.swappiness | 60 | 100（配合 zram） |
| vm.laptop_mode | 0 | 5 |
| 脏页回写 | 默认 | 延后到 15s |

> 说明：i9-14900HX 的 PPD `balanced` 与 `performance` 只差 EPP 提示，
> 都支持睿频到最高。玩 CS2 这类游戏时 `performance` 的帧稳定性略好；
> 若你更在意安静/低温，把 `/etc/default/power-tune` 里
> `PROFILE_ON_AC` 改成 `balanced` 即可。

## 安装

```bash
sudo bash ~/power-policy/install.sh
```

安装后：插拔电源自动切换，立即生效。

## 常用操作

```bash
# 查看当前配置与 PPD
cat /etc/default/power-tune
powerprofilesctl get

# 临时切 PPD
powerprofilesctl set performance   # 或 balanced / power-saver

# 改完配置后手动应用一次
sudo /usr/local/sbin/power-tune

# 查看日志
journalctl -t power-tune -n 20 --no-pager

# 卸载（保留配置）
sudo bash ~/power-policy/uninstall.sh
```

## 还能进一步榨性能/续航

1. **【最大续航提升】BIOS 开启混合显卡 / 切换 MUX**
   现在系统里只有 RTX 4080（`card1`，没有 `i915`），说明核显（UHD 770）在 BIOS 里
   被禁用（独显直连）。仅这一项就让你待机功耗多出约 5~10W。
   进 BIOS 找 `GPU Mode` / `Hybrid Graphics` / `Display Mode` 设为 Hybrid，
   或在 MECHREVO 控制中心切换，重启后应能看到 Intel 核显，续航会明显改善。

2. **【电池寿命】充电限制**
   你的电池健康度目前 100%，但 Linux 下没有暴露 `charge_control_end_threshold`，
   无法从系统侧设定。若长期插电使用，建议在 BIOS 里找 `Battery Health` /
   `Charge Limit` 设为 80%，可显著延长寿命。

3. **深度体检**（会在屏幕上跑约 10 分钟，需保持插电）
   ```bash
   sudo powertop --calibrate
   ```
   之后 `sudo powertop` 看是否有异常唤醒源（PowerTOP → Wakeups）。

4. **游戏时确认独显直连与 Dynamic Boost 正常**
   ```bash
   nvidia-smi --query-gpu=name,power.draw,power.limit,clocks.sm --format=csv
   ```

## 安全性

- 所有改动都可逆：`uninstall.sh` 恢复默认，且不会动 PPD/thermald/zram 本身。
- 唯一有风险的是电池下把 PCIe ASPM 设为 `powersave`；若遇到 NVMe/网卡异常，
  把 `/etc/default/power-tune` 的 `ASPM_ON_BAT` 改为 `default` 即可。
- 与 TLP 互斥（两者会争抢 CPU 策略），本方案刻意不装 TLP，与你的
  `setup-essentials.sh` 保持一致。
