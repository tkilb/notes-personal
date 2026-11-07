# Fix Plan for Sleep/Resume Failure (2026-03-08)

Based on the latest diagnostics, the system is waking up from sleep but failing to restore the Graphics Engine state, leading to a black screen and Xid 69 errors.

## Phase 1: OS Configuration (AI can help here)

### Step 1: Blacklist Failing DDR5 Sensor Driver
```bash
echo "blacklist spd5118" | sudo tee /etc/modprobe.d/disable-spd5118.conf
```

### Step 2: Disable Spontaneous Wakeup Triggers
Update `/etc/tmpfiles.d/disable-usb-wake.conf` to include more devices that might be jolting the system:
```bash
echo 'w /proc/acpi/wakeup - - - - PEG1' | sudo tee -a /etc/tmpfiles.d/disable-usb-wake.conf
echo 'w /proc/acpi/wakeup - - - - PXSX' | sudo tee -a /etc/tmpfiles.d/disable-usb-wake.conf
echo 'w /proc/acpi/wakeup - - - - RP02' | sudo tee -a /etc/tmpfiles.d/disable-usb-wake.conf
echo 'w /proc/acpi/wakeup - - - - RP03' | sudo tee -a /etc/tmpfiles.d/disable-usb-wake.conf
echo 'w /proc/acpi/wakeup - - - - RP21' | sudo tee -a /etc/tmpfiles.d/disable-usb-wake.conf
```

### Step 3: Rebuild Initramfs
Ensure the NVIDIA modules and modprobe options are correctly synchronized.
```bash
sudo mkinitcpio -P
```

## Phase 2: BIOS Adjustments (User Action Required)

### Step 4: Enable Resizable BAR
1. Reboot into BIOS (MSI Z690).
2. Ensure **"Above 4G Decoding"** is Enabled.
3. Set **"Re-Size BAR Support"** to Enabled.
4. Save and Exit.

## Phase 3: Validation
After applying the above:
1. Suspend the machine.
2. Resume and check if the monitor displays the login screen.
3. If it fails, check `journalctl -b 0 | grep NVRM` for any new Xid errors.
