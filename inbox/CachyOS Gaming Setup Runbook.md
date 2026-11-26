---
uid: 3f9a56c2-8412-4217-91de-01a25bd78f14
title: CachyOS Gaming Setup Runbook
kind: guide
source: "Self"
date: 2026-11-25
tags: [cachyos, arch-linux, gaming, steam, proton, performance]
people: []
related: []
---

# CachyOS Gaming Setup Runbook

CachyOS comes with performance-tuned kernels (BORE, sched-ext) and x86-64-v3/v4 compiler optimizations out of the box. Follow this runbook to take a fresh installation to a fully tuned gaming workstation.

---

## Phase 1: System Baseline & Hardware Drivers

### 1. Update Package Databases & Optimize Mirrors
Rank fastest mirrors and sync system packages:
```bash
sudo cachyos-rate-mirrors
sudo pacman -Syu
```

### 2. Verify GPU Drivers
CachyOS uses `chwd` (CachyOS Hardware Detection) to install the correct drivers during initial setup. Verify that the correct driver stack is loaded:

* **NVIDIA:**
  ```bash
  # Check driver status
  nvidia-smi
  
  # If proprietary drivers were not installed during ISO setup:
  sudo chwd -a
  ```
* **AMD (RADV Vulkan Stack):**
  Ensure the open-source Mesa RADV stack and 32-bit libraries are installed:
  ```bash
  sudo pacman -S --needed vulkan-radeon lib32-vulkan-radeon mesa lib32-mesa
  ```
* **Intel Arc:**
  ```bash
  sudo pacman -S --needed vulkan-intel lib32-vulkan-intel mesa lib32-mesa
  ```

---

## Phase 2: Core Gaming Stack

### 1. Install the CachyOS Gaming Meta-Package
CachyOS provides a curated meta-package bundling Wine dependencies, 32-bit libraries, GameMode, and common game launcher dependencies:
```bash
sudo pacman -S --needed cachyos-gaming-meta
```

### 2. Install Launchers & Compatibility Tools
Install Steam, alternative client managers (Lutris / Heroic for Epic & GOG), and Proton management utilities:
```bash
sudo pacman -S --needed steam lutris heroic-games-launcher-bin protonup-qt
```

### 3. Setup Proton-GE & Proton-CachyOS
1. Launch **ProtonUp-Qt**:
   ```bash
   protonup-qt
   ```
2. Select **Steam** (or **Heroic** / **Lutris**) as the target.
3. Click **Add version** and install:
   * **GE-Proton** (latest stable release)
   * **Proton-CachyOS** (optimized build targeting the CachyOS kernel)
4. Restart Steam so it recognizes the newly installed runtimes.

---

## Phase 3: Kernel Schedulers & Performance Tuning

### 1. Sched-EXT (`scx`) Framework
CachyOS includes support for extensible BPF schedulers (`sched-ext`), which significantly improve frame consistency and reduce latency under CPU load.

Check available schedulers:
```bash
pacman -Qs scx-scheds
```

Common recommended schedulers:
* `scx_lavd`: Optimized for gaming and latency-sensitive desktop workloads.
* `scx_bpfland`: Balanced scheduler for mixed interactive workloads.
* `scx_rusty`: Multi-core aware general performance scheduler.

To configure and enable `scx_lavd` as a persistent systemd service:
Set `SCX_SCHEDULER=scx_lavd` in `/etc/default/scx`, then enable:
```bash
sudo systemctl enable --now scx
```

### 2. GameMode Configuration
Enable the GameMode daemon to apply automatic CPU governor, GPU performance clocks, and I/O priority adjustments while games are active:
```bash
systemctl --user enable --now gamemoded
```

---

## Phase 4: Overlays & Monitoring

Install **MangoHud** (HUD overlay for FPS, temperatures, frame-times) and **Goverlay** (GUI configuration tool):
```bash
sudo pacman -S --needed mangohud lib32-mangohud goverlay
```

To test MangoHud:
```bash
mangohud vkcube
```

---

## Phase 5: Storage & Drives

### 1. Enable TRIM for SSD/NVMe
Ensure background trim is active:
```bash
sudo systemctl enable --now fstrim.timer
```

### 2. Secondary Drives (Game Libraries)
* **Preferred:** Format extra gaming storage drives as **Btrfs** or **ext4**.
* **Mounting an existing NTFS library (read/write fallback):** If temporarily accessing an NTFS drive from Windows, ensure it is mounted with `uid=1000,gid=1000,windows_names` options in `/etc/fstab` to avoid Wine/Proton symlink failures.

---

## Phase 6: Per-Game Steam Launch Options

Right-click any game in Steam $\rightarrow$ **Properties** $\rightarrow$ **Launch Options**:

* **Basic (GameMode + MangoHud):**
  ```text
  mangohud gamemoderun %command%
  ```
* **Gamescope (Embedded compositor for upscaling/FSR & resolution management):**
  ```bash
  sudo pacman -S --needed gamescope
  ```
  Launch option example (rendering at 1080p, upscaling to 1440p):
  ```text
  gamescope -w 1920 -h 1080 -W 2560 -H 1440 -F fsr -- gamemoderun %command%
  ```
