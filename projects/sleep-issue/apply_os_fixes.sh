#!/bin/bash

echo "--- Applying Sleep/Resume Fixes ---"

# 1. Blacklist failing spd5118 driver
echo "Blacklisting spd5118..."
echo "blacklist spd5118" | tee /etc/modprobe.d/disable-spd5118.conf

# 2. Configure persistent ACPI wakeup rules
echo "Configuring ACPI wakeup rules..."
cat <<EOF | tee /etc/tmpfiles.d/disable-usb-wake.conf
# Prevent peripherals and PCIe jolts from waking the system prematurely
w /proc/acpi/wakeup - - - - XHCI
w /proc/acpi/wakeup - - - - PEG1
w /proc/acpi/wakeup - - - - PXSX
w /proc/acpi/wakeup - - - - RP02
w /proc/acpi/wakeup - - - - RP03
w /proc/acpi/wakeup - - - - RP21
EOF

# 3. Apply wakeup rules immediately
echo "Applying wakeup rules to current session..."
for dev in XHCI PEG1 PXSX RP02 RP03 RP21; do
    if grep -q "$dev.*enabled" /proc/acpi/wakeup; then
        echo "$dev" | tee /proc/acpi/wakeup
    fi
done

# 4. Rebuild initramfs
echo "Rebuilding initramfs (this may take a minute)..."
mkinitcpio -P

echo "--- OS Fixes Applied ---"
echo "Next step: Reboot into BIOS and enable 'Above 4G Decoding' and 'Resizable BAR'."
