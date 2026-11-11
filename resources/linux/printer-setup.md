---
uid: 2b049118-7929-4715-a58a-cf3eaafc1343
title: printer-setup
kind: runbook
source: ""
date: ""
tags: []
people: []
related: []
---

# Driverless Linux Printer & Scanner Runbook (Arch Linux)

This runbook covers configuring printing and scanning for modern multifunction printers (Brother, HP, Canon, Epson) using standard **driverless** protocols (**IPP Everywhere / AirPrint** and **eSCL / AirScan**).

No proprietary binary blobs or printer-specific AUR drivers are required.

---

## 1. Prerequisites & Required Packages

Install CUPS, discovery utilities, and SANE with the driverless `sane-airscan` backend:

```bash
sudo pacman -S --needed \
  cups \
  cups-filters \
  libppd \
  avahi \
  nss-mdns \
  sane \
  sane-airscan
```

> **Note for USB connection:** If your printer connects via USB instead of Wi-Fi/Ethernet, also install `ipp-usb` (`sudo pacman -S ipp-usb`) and enable its daemon (`sudo systemctl enable --now ipp-usb`). This exposes USB IPP printers to localhost HTTP/IPP.

---

## 2. Enable Core System Services

Start and enable the CUPS print scheduler and the Avahi mDNS discovery daemon:

```bash
sudo systemctl enable --now cups.service
sudo systemctl enable --now avahi-daemon.service
```

### Enable mDNS Host Resolution (Optional but Recommended)

To resolve `.local` printer hostnames without manual IP management, `mdns_minimal [NOTFOUND=return]` must be inserted **inside the existing `hosts:` line** in `/etc/nsswitch.conf` (do **not** append it to the bottom of the file).

**Quick One-Liner:**

```bash
sudo sed -i '/^hosts:/ s/\(mymachines\)/\1 mdns_minimal [NOTFOUND=return]/' /etc/nsswitch.conf
```

**Or Edit Manually (`sudo vim /etc/nsswitch.conf`):**
Find the line starting with `hosts:` and change it:

```diff
- hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
+ hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns
```

---

## 3. Printing Setup (CUPS + IPP Everywhere)

### Step 3.1: Discover Available Network Printers

Run the `driverless` discovery command or query CUPS backends:

```bash
driverless
# Output: ipp://Brother%20HL-L2395DW%20series._ipp._tcp.local/
```

Alternatively, search using `lpinfo`:

```bash
lpinfo -v | grep -iE 'ipp|dnssd'
```

### Step 3.2: Add the Printer to CUPS

Use the exact URI returned from `driverless`:

```bash
sudo lpadmin -p "Brother_Printer" \
  -E \
  -v "ipp://Brother%20HL-L2395DW%20series._ipp._tcp.local/" \
  -m everywhere
```

> If using a static IP or DHCP reservation instead of mDNS:
> `sudo lpadmin -p "Brother_Printer" -E -v "ipp://192.168.0.246/ipp/print" -m everywhere`

### Step 3.3: Set Default & Verify

```bash
# Set as system default printer
lpoptions -d Brother_Printer

# Verify status
lpstat -p -d

# Send a test print
lp -d Brother_Printer /usr/share/cups/data/testprint
```

---

## 4. Scanning Setup (SANE + AirScan)

The `sane-airscan` backend automatically discovers eSCL/WSD network and `ipp-usb` scanners via mDNS.

### Step 4.1: Test Discovery

```bash
scanimage -L
```

Expected output:

```text
device `airscan:e0:Brother HL-L2395DW series' is a eSCL Brother HL-L2395DW series ip=192.168.0.246
```

### Step 4.2: Test a Scan via CLI

```bash
# Scan flatbed to PDF (300 DPI)
scanimage -d "airscan:e0:Brother HL-L2395DW series" \
  --format=pdf \
  --resolution 300 \
  > ~/test-scan.pdf

# Scan from Automatic Document Feeder (ADF) if equipped
scanimage -d "airscan:e0:Brother HL-L2395DW series" \
  --source "ADF" \
  --format=pdf \
  --resolution 300 \
  > ~/test-scan-adf.pdf
```

To list all device-specific scan options (color modes, resolutions, paper sources):

```bash
scanimage --help -d "airscan:e0:Brother HL-L2395DW series"
```

---

## 5. Terminal & TUI Tools

### Printing Management

- **CLI Inspection:**
  ```bash
  # Check printer queue and status
  lpstat -t

  # Check active jobs
  lpstat -o

  # Cancel all jobs or a specific job
  cancel -a
  cancel <job-id>
  ```
- **TUI (Optional - AUR):**
  - [`cupstui`](https://github.com/icortesb/cupstui): Interactive terminal interface for monitoring CUPS queues and jobs.
- **Web Admin in Terminal:**
  ```bash
  w3m http://localhost:631
  ```

### Scanning Management

- **TUI (Optional - AUR/Cargo):**
  - [`sanetui`](https://github.com/nathawatc/sanetui): Terminal UI with device discovery, scanner option configuration, terminal image previews (Kitty/Sixel), and direct PDF export.
- **Quick Shell Alias / Script:**
  Add a helper to `~/.bashrc` or `~/.zshrc`:
  ```bash
  scan2pdf() {
    local output="${1:-scan_$(date +%Y%m%d_%H%M%S).pdf}"
    scanimage --format=pdf --resolution 300 > "$output"
    echo "Saved scan to $output"
  }
  ```

---

## 6. Troubleshooting

| Issue                                          | Likely Cause                                         | Fix                                                                                                                                          |
| ---------------------------------------------- | ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `driverless` or `scanimage -L` finds nothing   | `avahi-daemon` not running or firewall blocking mDNS | Run `systemctl status avahi-daemon`. Open UDP port `5353` and TCP port `631` if a firewall (e.g., `ufw`, `nftables`, `firewalld`) is active. |
| Printer appears paused after waking from sleep | Network timeout                                      | Enable the queue with `cupsenable Brother_Printer && cupsaccept Brother_Printer`.                                                            |
| Printer IP changes frequently                  | Dynamic DHCP lease                                   | Assign a static IP or DHCP MAC reservation in your router.                                                                                   |
| Scan fails with `Device busy`                  | Scan unit locked or another client is scanning       | Power cycle the scanner or wait for any active job to finish.                                                                                |
