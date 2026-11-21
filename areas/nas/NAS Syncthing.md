---
uid: f1e56e61-ad0f-4208-9fed-e8a68237c8c9
title: NAS Syncthing
kind: runbook
source: ""
date: ""
tags: []
people: []
related: []
---
# Runbook: Setup Syncthing on Debian Server (Headless UI)

## Context & Network Ports
- **Target Server:** Debian 12 (Raspberry Pi / `pi-server` at `192.168.0.123`)
- **Workstation:** Arch Linux (`linux-box`)
- **GUI Port:** `8384` (Default: `127.0.0.1:8384`)
- **Sync Protocol Port:** `22000/tcp` and `22000/udp` (QUIC / data transfer)
- **Local Discovery Port:** `21027/udp`

---

## 1. Install Syncthing on the Debian Server

SSH into the Debian server:
```bash
ssh pi-server
```

Install Syncthing from official Debian repositories:
```bash
sudo apt update
sudo apt install -y syncthing
```

*(Optional: For bleeding-edge releases, Syncthing maintains official apt repositories at `apt.syncthing.net`.)*

---

## 2. Enable and Start the Systemd Service

Debian packages include a systemd template unit `syncthing@<username>.service`. This starts Syncthing automatically on boot without requiring an active login session or systemd linger:

```bash
# Replace <user> with your Debian username (e.g. pi or linux-book)
sudo systemctl enable --now syncthing@<user>.service

# Verify the service is active and running
sudo systemctl status syncthing@<user>.service
```

> **Note:** Starting the service once generates the initial configuration and keys in `~/.local/state/syncthing/` (or `~/.config/syncthing/` on older versions).

---

## 3. Accessing the Headless Web UI

By default, Syncthing binds its Web GUI only to `127.0.0.1:8384` for security. Choose one of two methods to access it:

### Method A: SSH Port Forwarding (Recommended & Most Secure)

Forward remote port 8384 to your local workstation over SSH:

```bash
# Run from your Arch Linux workstation:
ssh -L 8384:127.0.0.1:8384 pi-server
```

*(Tip: To make this persistent, add `LocalForward 8384 127.0.0.1:8384` under `Host pi-server` in `~/.ssh/config`.)*

1. Open your browser on Arch Linux and navigate to:
   ```
   http://localhost:8384
   ```
2. **Immediate Security Step:** Go to **Actions** -> **Settings** -> **GUI**:
   - Set a **GUI Authentication User** and strong **Password**.
   - Check **Use HTTPS for GUI**.
   - Click **Save**. Syncthing will restart its web interface.

---

### Method B: Direct LAN Access (`0.0.0.0:8384`)

By default, Syncthing binds to `127.0.0.1` (localhost), which only accepts browser connections from the Debian server itself. Since the server is headless, change the listen address to `0.0.0.0:8384` so any machine on your local network (e.g. your Arch workstation) can open the dashboard.

All commands below are executed **on the Debian server** (after running `ssh pi-server`):

1. **Stop the Syncthing service:**
   > **Important:** Syncthing stores configuration in memory. If you edit `config.xml` while Syncthing is running, your edits will be overwritten and reverted when the service stops or saves.
   ```bash
   # Replace <user> with your Debian username (e.g. pi or linux-book, or $USER)
   sudo systemctl stop syncthing@<user>.service
   ```

2. **Locate and edit `config.xml`:**
   Syncthing stores its configuration file at:
   - Modern Debian / Syncthing v1.23+: `~/.local/state/syncthing/config.xml`
   - Older versions: `~/.config/syncthing/config.xml`

   Choose either manual editing or the automated command:

   - **Option 1: Manual Edit (using nano or vim):**
     ```bash
     nano ~/.local/state/syncthing/config.xml
     # (If not found, try: nano ~/.config/syncthing/config.xml)
     ```
     Find the `<gui>` section and change `127.0.0.1:8384` to `0.0.0.0:8384`:
     ```xml
     <!-- BEFORE: -->
     <gui enabled="true" tls="false" debugging="false">
         <address>127.0.0.1:8384</address>

     <!-- AFTER: -->
     <gui enabled="true" tls="false" debugging="false">
         <address>0.0.0.0:8384</address>
     ```
     Save and exit (`Ctrl + O`, `Enter`, then `Ctrl + X` in nano).

   - **Option 2: Automated Command (using sed):**
     ```bash
     CONFIG_FILE="$HOME/.local/state/syncthing/config.xml"
     [ ! -f "$CONFIG_FILE" ] && CONFIG_FILE="$HOME/.config/syncthing/config.xml"

     sed -i 's|<address>127.0.0.1:8384</address>|<address>0.0.0.0:8384</address>|' "$CONFIG_FILE"
     ```

3. **Restart the service:**
   ```bash
   sudo systemctl start syncthing@<user>.service
   ```

4. **Open the Web UI in your browser:**
   From your Arch Linux workstation, navigate to:
   ```
   http://192.168.0.123:8384
   ```

5. **CRITICAL SECURITY STEP — Set a Password Immediately:**
   Because `0.0.0.0` allows anyone on your local network to access the web panel without credentials:
   - You will see an alert banner: *"The Syncthing admin interface is configured to allow remote access without a password."*
   - Click **Settings** (or **Actions** -> **Settings** -> **GUI** tab).
   - Enter a **GUI Authentication User** (e.g. your username).
   - Enter a strong **GUI Authentication Password**.
   - Check **Use HTTPS for GUI** (encrypts dashboard traffic and credentials over LAN).
   - Click **Save**. The page will reload over `https://192.168.0.123:8384` (accept the self-signed certificate in your browser).

---

## 4. Firewall Configuration (If UFW is Active on Debian)

If UFW or another firewall is running on the Debian server, permit the necessary ports:

```bash
# Sync transfer traffic
sudo ufw allow 22000/tcp comment 'Syncthing Sync'
sudo ufw allow 22000/udp comment 'Syncthing QUIC'

# Local device discovery broadcast
sudo ufw allow 21027/udp comment 'Syncthing Discovery'

# Web GUI (Only if using Method B for direct LAN access)
sudo ufw allow 8384/tcp comment 'Syncthing Web GUI'
```

---

## 5. Pairing the Debian Server with Arch Linux Workstation

1. **Obtain Debian Server Device ID:**
   In the server Web GUI, click **Actions** -> **Show ID** (or run `syncthing --device-id` on the server).
2. **Add Device on Arch Workstation:**
   Open local Syncthing on Arch (`http://localhost:8384`), click **Add Remote Device**, paste the Device ID, and assign a friendly name (e.g. `pi-server`).
3. **Confirm on Debian Server:**
   Return to the Debian Web GUI and click **Add Device** when the prompt appears.
4. **Share Folders:**
   In folder settings on either machine, toggle the remote device to begin synchronization.

---

## 6. System Tuning: Increase Inotify File Watch Limit

Linux limits how many files a user can monitor in real time with inotify. Syncthing may show a warning if monitoring large directory trees:

```bash
# Run on the Debian server:
echo "fs.inotify.max_user_watches=204800" | sudo tee /etc/sysctl.d/90-syncthing.conf
sudo sysctl --system
```

---

## 7. Troubleshooting

- **Check Service Logs:**
  ```bash
  journalctl -u syncthing@<user>.service -n 50 -f
  ```
- **Port Conflict (Port 8384 already in use on workstation):**
  If your Arch machine is already running Syncthing locally on port 8384, map the remote port to a different local port (e.g. 8385):
  ```bash
  ssh -L 8385:127.0.0.1:8384 pi-server
  # Then browse to http://localhost:8385
  ```
- **Reset Forgotten GUI Password:**
  If you ever get locked out of the GUI:
  ```bash
  sudo systemctl stop syncthing@<user>.service
  # In config.xml, delete the <user> and <password> tags inside <gui>...</gui>
  sudo systemctl start syncthing@<user>.service
  ```
