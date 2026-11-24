---
uid: 9c12e847-5d20-4a8e-b541-628bdf6751e3
title: Discover Overlay Setup
kind: runbook
source: adhoc
date: 2026-11-23
tags: [hyprland, discord, overlay, runbook, arch]
people: []
id: discover-overlay-setup
aliases: []
related: ["[[Plan]]"]
---

# Discover Overlay Setup on Hyprland

Step-by-step procedure to install, configure, and integrate `discover-overlay` with Hyprland on Arch Linux.

---

## Prerequisites
- Arch Linux with Hyprland.
- Discord installed (Official client, Flatpak, or Vesktop).
- An AUR helper (`paru` or `yay`).

---

## Step 1: Install from AUR

Using `paru`:
```bash
paru -S discover-overlay python-pkg-resources
```

Or using `yay`:
```bash
yay -S discover-overlay python-pkg-resources
```

*Note on Python 3.14+ / Setuptools 81+:* `pkg_resources` was separated from Setuptools into `python-pkg-resources` in the AUR. If you encounter `ModuleNotFoundError: No module named 'pkg_resources'`, install `python-pkg-resources`.


---

## Step 2: Ensure Discord IPC Socket Access

Discover Overlay queries Discord via a local Unix socket.

1. Verify socket presence while Discord is running:
   ```bash
   ls -la "${XDG_RUNTIME_DIR}/discord-ipc-0"
   ```
2. If using **Flatpak Discord**, grant permission to expose the IPC socket:
   ```bash
   flatpak override --user --filesystem=xdg-run/discord-ipc-0 com.discordapp.Discord
   ```
3. If using **Vesktop**, ensure `DiscordRPC` / Rich Presence is enabled in Vesktop settings.

---

## Step 3: Hyprland Layer Rules

In your Hyprland configuration (typically `~/.config/hypr/hyprland.conf`), configure rules so the overlay does not suffer from distracting animations or unwanted blur:

```ini
# Prevent animations on the Discover Overlay layer surface
layerrule = noanim, discover-overlay
```

If running Discover Overlay in standard window mode (fallback if not using layer-shell):
```ini
windowrule = float, title:^(Discover Overlay)$
windowrule = nofocus, title:^(Discover Overlay)$
windowrule = pin, title:^(Discover Overlay)$
windowrule = noshadow, title:^(Discover Overlay)$
windowrule = noborder, title:^(Discover Overlay)$
```

---

## Step 4: First-Time Configuration

1. Launch Discord first, connect to a voice channel.
2. Launch Discover Overlay settings:
   ```bash
   discover-overlay
   ```
3. Under **Overview**:
   - Set **Overlay Location** (Top-Left, Top-Right, etc.) or click **Place Window** to position freely.
   - Set layout orientation (**Display Horizontally** vs vertically).
4. Under **Voice**:
   - Toggle **Show Test Content** to preview avatars without an active call.
   - Adjust **Avatar Size** and **Verticle Edge Padding** (screen margin offset).
   - Toggle **Display Speakers Only** if you only want talking members visible.

---

## Step 5: Startup Workflow

### On-Demand Launch (Current Setup)
Launch whenever gaming:
- **Launcher:** Press `ALT + SPACE` and run `Discover Overlay`.
- **Terminal:** Run `discover-overlay &`

### Optional Autostart
If you want it to run automatically on login in the future:
- **Hyprland:** Add `hl.exec_cmd("discover-overlay --minimized &")` into `hl.on("hyprland.start", ...)` in `~/.dotfiles/hypr/hyprland.lua`.
- **XDG:** Enable **Run Overlay on Startup** in Discover Overlay's **Core** tab.
