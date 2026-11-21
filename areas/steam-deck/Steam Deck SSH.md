---
uid: e329775b-765b-4f46-a070-0c31de5a1d9e
title: Steam Deck SSH
kind: runbook
source: adhoc
date: 2026-11-20
tags: []
people: []
related: []
---
# SSH Access from Arch Linux to Steam Deck

## Overview

This guide covers how to configure SSH access from an Arch Linux machine to a Steam Deck (SteamOS 3.x, which is Arch-based).

## Prerequisites

- Steam Deck running SteamOS 3.x
- Arch Linux machine on the same network
- Physical access to the Steam Deck (required for initial setup)

## Step 1: Enable SSH on Steam Deck

SSH is disabled by default on Steam Deck. Enable it via the Steam Deck terminal:

1. Press the **Steam button** → **Power** → **Switch to Desktop**
2. Open **Konsole** (terminal emulator)
3. Run the following commands:

```bash
# Set a password for the 'deck' user
passwd

# Enable and start the SSH service
sudo systemctl enable sshd
sudo systemctl start sshd
```

## Step 2: Generate SSH Key Pair (on Arch Linux)

On your Arch Linux machine, generate an SSH key pair if you don't have one:

```bash
ssh-keygen -t ed25519 -C "steam-deck" -f ~/.ssh/steam-deck
```

This creates:

- `~/.ssh/steam-deck` (private key)
- `~/.ssh/steam-deck.pub` (public key)

## Step 3: Copy Public Key to Steam Deck

Transfer your public key to the Steam Deck:

```bash
ssh-copy-id -i ~/.ssh/steam-deck.pub deck@<steam-deck-ip>
```

Or manually:

```bash
# Copy the public key content
cat ~/.ssh/steam-deck.pub

# SSH to Steam Deck (password authentication)
ssh deck@<steam-deck-ip>

# On Steam Deck, create .ssh directory and add key
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "<your-public-key>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit
```

## Step 4: Connect via SSH

Now you can connect using key-based authentication:

```bash
ssh -i ~/.ssh/steam-deck deck@<steam-deck-ip>
```

## Step 5: (Optional) Add SSH Config Entry

Add an entry to `~/.ssh/config` on Arch Linux for easier access:

```
Host steamdeck
    HostName <steam-deck-ip>
    User deck
    IdentityFile ~/.ssh/steam-deck
    IdentitiesOnly yes
```

Then connect simply with:

```bash
ssh steamdeck
```

## Finding Your Steam Deck's IP Address

On the Steam Deck terminal:

```bash
ip addr show wlan0    # For WiFi
ip addr show eth0     # For Ethernet (if using dock)
```

Or from SteamOS settings: **Settings** → **Network**

## Troubleshooting

### Connection Refused

- Ensure SSH service is running: `sudo systemctl status sshd`
- Check firewall settings on Steam Deck

### Permission Denied

- Verify key permissions: `chmod 600 ~/.ssh/steam-deck`
- Check `~/.ssh/authorized_keys` on Steam Deck
- Ensure correct ownership: `chown -R deck:deck ~/.ssh`

### Steam Deck Goes to Sleep

The Steam Deck may suspend and disconnect. To prevent this:

```bash
# On Steam Deck, disable auto-suspend (temporary)
sudo systemctl mask sleep.target suspend.target
```

## Security Notes

- Keep your private key secure (`chmod 600`)
- Consider disabling password authentication after key setup
- Use a strong password for the `deck` user
- Keep SteamOS updated: `sudo pacman -Syu`
