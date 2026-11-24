---
uid: 7f5a3b68-2c49-4eb1-9988-15cf43ef7a12
title: Discord Overlay Plan
kind: plan
source: adhoc
date: 2026-11-23
tags: [hyprland, discord, overlay, linux]
people: []
id: discord-overlay-plan
aliases: [discord-overlay]
related: ["[[Discover Overlay Setup]]", "[[Noise Suppression]]"]
---

# Discord Overlay Plan

## Objective
Set up an in-game voice and speaker overlay and background noise suppression for Discord running under Arch Linux and Hyprland (Wayland).

---

## Technical Approach & Architecture

- **Overlay Tool:** Discover Overlay (`discover-overlay`)
- **Integration Layer:** `gtk-layer-shell` (Wayland layer surface)
- **Audio Processing:** PipeWire filter-chain (`noise-suppression-for-voice` / RNNoise)
- **Data Source:** Local Discord IPC socket (`$XDG_RUNTIME_DIR/discord-ipc-0`)
- **Key Advantages:**
  - True Wayland overlay without XWayland fullscreen capturing issues.
  - Transparent, click-through, and hardware-accelerated.
  - System-level noise cancellation filtering mechanical keyboard and background hum without Discord client reliance.

---

## Tasks

- [x] **Step 1: Install Package**
  - Install `discover-overlay` and `python-pkg-resources` via AUR. [Completed]
- [x] **Step 2: Discord RPC Verification**
  - Confirm Discord (or Vesktop) provides the local IPC socket at `$XDG_RUNTIME_DIR/discord-ipc-0`. [Completed: socket active at /run/user/1000/discord-ipc-0]
- [x] **Step 3: Initial Configuration (GUI)**
  - Launch `discover-overlay` to configure screen location, avatar size, and voice display preferences. [Completed]
- [x] **Step 4: Startup Strategy**
  - Configured for manual on-demand launch via Rofi (`ALT + SPACE`) or terminal (`discover-overlay`) when gaming to save resources. [Completed]
- [x] **Step 5: Background Noise Suppression**
  - Installed `noise-suppression-for-voice` and created `~/.config/pipewire/pipewire.conf.d/99-input-denoising.conf`. [Completed]

---

## References & Related Notes
- [[Discover Overlay Setup]] (Step-by-step installation and configuration runbook)
- [[Noise Suppression]] (PipeWire RNNoise filter-chain runbook)
