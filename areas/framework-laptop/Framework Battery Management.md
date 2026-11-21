---
uid: 922c0a67-a879-4e02-8747-4a1142c36d2e
title: Framework Battery Management
kind: guide
source: ""
date: ""
tags: []
people: []
related: []
---
# Framework 13 AMD Battery Optimization & Power Tuning (Arch Linux)

Comprehensive guide and operational runbook for optimizing battery life and idle power consumption on Framework Laptop 13 (AMD Ryzen / Krackan / Zen 4 & 5) running Arch Linux and Hyprland.

---

## 1. Quick Diagnostics & Baseline Inspection

### Measure Real-Time Discharge Rate (Watts)
Run this one-liner to calculate instantaneous power consumption:
```bash
python3 -c '
v = int(open("/sys/class/power_supply/BAT1/voltage_now").read().strip()) / 1e6
c = int(open("/sys/class/power_supply/BAT1/current_now").read().strip()) / 1e6
print(f"Current Draw: {v * c:.2f} W (Voltage: {v:.2f}V, Current: {c:.2f}A)")
'
```
*Healthy idle target:* ~4.5W – 6.5W on battery with moderate brightness.

### Check Power Profile & CPU Governor
```bash
powerprofilesctl get
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
```
*Expected on battery:* `power-saver`, `amd-pstate-epp`, and `power`.

---

## 2. AMD Panel Power Savings (ABM / Adaptive Backlight Modulation)

### Why
On AMD Radeon integrated GPUs (e.g., 780M, 860M, 880M) paired with the 2.8K display, AMD ABM adjusts pixel contrast while lowering the backlight level. Under GNOME/KDE, `power-profiles-daemon` manages this automatically, but standalone Wayland compositors (Hyprland, Sway) leave it disabled (`0`).

### Impact
Saves **0.5W – 1.5W** on display power.

### Testing Immediately
```bash
# Levels: 1 (subtle), 2 (balanced), 3 (aggressive), 4 (maximum)
echo 2 | sudo tee /sys/class/drm/card*-eDP-*/amdgpu/panel_power_savings
```

### Persistent Configuration (udev Rule)
Create `/etc/udev/rules.d/99-amd-abm.rules`:
```udev
ACTION=="add", SUBSYSTEM=="drm", KERNEL=="card*", ATTR{amdgpu/panel_power_savings}="2"
```
Reload rules:
```bash
sudo udevadm control --reload-rules && sudo udevadm trigger
```

---

## 3. PCIe ASPM Policy (`powersupersave`)

### Why
Active State Power Management (ASPM) allows PCIe bus links (NVMe SSD, Wi-Fi 7 controller, root bridges) to drop into deep L0s/L1 power states when idle. The default Linux kernel policy is `[default]`.

### Impact
Saves **0.5W – 1.0W** idle draw.

### Verification
```bash
cat /sys/module/pcie_aspm/parameters/policy
# [default] performance powersave powersupersave
```

### Configuration
Add `pcie_aspm.policy=powersupersave` to your kernel command line.
For `systemd-boot`, edit your active boot entry in `/boot/loader/entries/*.conf` and append to `options`:
```text
pcie_aspm.policy=powersupersave
```

---

## 4. Display Backlight & Hypridle Dimming

### Why
The 2.8K 120Hz display at 100% brightness pulls ~3.5W–4.5W alone. Running at 35%–50% indoors drastically extends battery runtime.

### Progressive Dimming in Hypridle
Configured in `~/.dotfiles/hypr/hypridle.conf`:
```ini
# Dim backlight to 20% after 60s of inactivity on battery
listener {
    timeout = 60
    on-timeout = bash -c 'cat /sys/class/power_supply/BAT*/status 2>/dev/null | grep -q Discharging && brightnessctl -s set 20%'
    on-resume = brightnessctl -r
}
```

> [!NOTE]
> **Customizing & Tuning the Dim Listener:**
> - **Idle Timeout (`timeout = 60`):** Change to `90` if you frequently read long documents without moving the pointer or typing.
> - **Target Brightness (`set 20%`):** Change to `10%` for maximum power savings in low light, or `30%` if 20% is too dim for your environment.
> - **How restore works:** `brightnessctl -s` saves your previous brightness before dimming, and `-r` cleanly restores that exact saved level upon any keyboard/mouse activity.
> - **Multi-Host Safety:** The `grep -q Discharging` check ensures this listener is completely bypassed when plugged into a charger or when running on your desktop (`linux-box`).
> - **Applying Edits Live:** After editing `hypridle.conf`, reload hypridle immediately with:
>   ```bash
>   killall hypridle && hypridle &
>   ```


---

## 5. Framework Expansion Card Idle Drain

### Physical Hardware Quirk
- **USB-C Modules:** True pass-through; virtually 0 mW idle draw.
- **USB-A Modules:** Contain active translation chips that continuously draw **300–400 mW** each even with no device connected.
- **HDMI / DisplayPort Modules (Gen 1):** Draw **~1,000 mW (1W)** continuously due to onboard active DP-to-HDMI conversion.

### Recommendations
1. When traveling on battery, remove HDMI/DP modules or swap them with USB-C modules.
2. If keeping USB-A modules installed on AMD Framework 13, place them in the **front slots** (Slot 2 front-left or Slot 4 front-right) to minimize sleep power draw.

---

## 6. Wi-Fi & Bluetooth Radio Optimization

### NetworkManager Wi-Fi Power Save
Ensure Wi-Fi power saving is explicitly turned on in NetworkManager.
Create `/etc/NetworkManager/conf.d/wifi-powersave.conf`:
```ini
[connection]
wifi.powersave = 3
```
Restart NetworkManager:
```bash
sudo systemctl restart NetworkManager
```

### Bluetooth Radio
If no Bluetooth accessories are actively in use, disable the controller to avoid continuous background advertising/polling:
```bash
bluetoothctl power off
# Or block via rfkill
rfkill block bluetooth
```

---

## 7. Framework Sleep/Wake Service Verification

Ensure spurious USB and Thunderbolt wakeups are masked so s2idle sleep does not wake in a bag:
```bash
systemctl status framework-sleep-wake.service
```
This unit masks wakeup on `XHC0`, `XHC1`, `XHC3`, `XHC4`, `NHI0`, and `NHI1` in `/proc/acpi/wakeup`.
