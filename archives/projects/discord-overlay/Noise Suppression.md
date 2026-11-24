---
uid: 3e82bb19-410a-42cc-a590-349f7e815610
title: Noise Suppression (PipeWire RNNoise)
kind: runbook
source: adhoc
date: 2026-11-23
tags: [pipewire, audio, rnnoise, noise-suppression, linux]
people: []
id: pipewire-noise-suppression
aliases: []
related: ["[[Plan]]"]
---

# PipeWire Real-Time Noise Suppression (RNNoise)

Real-time microphone background noise cancellation using the RNNoise neural network model running in a native PipeWire filter-chain.

---

## 1. Prerequisites & Installation

Installed package from official Arch repos:
```bash
sudo pacman -S --needed noise-suppression-for-voice
```

Plugin binary: `/usr/lib/ladspa/librnnoise_ladspa.so`

---

## 2. Configuration

Configured via drop-in file: `~/.config/pipewire/pipewire.conf.d/99-input-denoising.conf`

Key properties:
- **`label = noise_suppressor_stereo`**: Matches stereo input (e.g. Fifine microphone).
- **`node.passive = true`**: Only captures and processes audio when an app is actively listening to the clean source, saving CPU.
- **`media.class = Audio/Source`**: Exposes the clean audio as a selectable recording device.

---

## 3. Reloading & Verification

Restart the user service:
```bash
systemctl --user restart pipewire
```

Verify the new virtual source is online:
```bash
wpctl status
```
Look under `Audio -> Sources` for `Noise Canceling source`.

---

## 4. Usage in Discord / Games

- In **Discord** (User Settings -> Voice & Video -> Input Device): Select **"Noise Canceling source"**.
- Turn Discord's built-in "Noise Suppression" to **None** or **Standard** to avoid double-processing.
