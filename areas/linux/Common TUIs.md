---
uid: cf68e113-c92b-4e86-a9c7-a0ab3a04b3f8
title: Common TUIs
kind: idea
source: ""
date: ""
tags: []
people: []
related: []
---
# Runbook: Regular TUIs

## bluetui - Bluetooth manager

- Install: `sudo pacman -S bluetui`
- Playbook: `ansible/playbooks/arch/tui.yaml`

## btop - System resource monitor

- Install: `sudo pacman -S btop`
- Playbook: `ansible/playbooks/arch/tui.yaml`

## caligula - Disk imager

- Install: `sudo pacman -S caligula`
- Playbook: `ansible/playbooks/arch/tui.yaml`

## cull - Disk usage analyzer

- Install: `yay -S cull-bin`
- Playbook: `ansible/playbooks/arch/tui.yaml`

## gophertube - Video downloader, browser and player

YouTube-like via gopher protocol, built from source with Go.

- Install: clone `KrishnaSSH/GopherTube` and `go install .`
- Playbook: `ansible/playbooks/arch/gophertube.yaml`
- Deps: `chafa`, `fzf`, `mpv`, `yt-dlp`

## lazygit - Git source control tool

- Install: `sudo pacman -S lazygit`
- Playbook: `ansible/playbooks/arch/tui.yaml`

## lazyrsync - Rsync Manager

- Install: `yay -S lazyrsync`
- Playbook: `ansible/playbooks/arch/tui.yaml`

## navi - Interactive cheatsheet tool

- Install: `sudo pacman -S navi`
- Playbook: `ansible/playbooks/arch/tui.yaml`

## wiremix - Audio mixer (PipeWire)

- Install: `sudo pacman -S wiremix`
- Playbook: `ansible/playbooks/arch/tui.yaml`

## yazi - Terminal file manager

- Install: `sudo pacman -S yazi`
- Playbook: `ansible/playbooks/arch/yazi.yaml` (also installs the
  `boydaihungst/mediainfo` plugin via `ya pkg add`)
