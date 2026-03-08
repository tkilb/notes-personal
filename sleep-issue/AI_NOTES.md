# AI Diagnostics Notes - Sleep/Resume Issue (Update 2026-03-08)

## System Status Confirmed
- **Driver:** `nvidia-open-dkms` 590.48.01 (Stable).
- **GPU:** RTX 3080 Ti (12GB VRAM).
- **Swap:** 16GB /swapfile active.
- **Parameters:** `PreserveVideoMemoryAllocations: 1` and `TemporaryFilePath: "/var/tmp"` are active.
- **Problem:** `Xid 69` on resume, instant `nvidia-resume.service` completion (suggests no data restored).

## New Findings
1. **Low Suspend Overhead:** `nvidia-suspend.service` only peaks at ~1GB memory usage. It should be much higher when saving 12GB of VRAM. This implies the state-saving is being bypassed or failing silently.
2. **Resizable BAR is Disabled:** motherboard supports it, but it's off. This can affect how the driver manages large memory blocks.
3. **`spd5118` Driver Failure:** The DDR5 temperature sensor driver is failing on every resume, likely causing I2C bus delays.
4. **PCIe Wakeups Enabled:** `PEG1` (GPU) and `PXSX` (Ethernet) are enabled for wakeup, which can "jolt" the driver during power transitions.

## Updated Fix Strategy

### Fix 1: Blacklist `spd5118` (Timing/I2C Stability)
Prevent the failing DDR5 sensor driver from interfering with the resume process.
```bash
echo "blacklist spd5118" | sudo tee /etc/modprobe.d/disable-spd5118.conf
```

### Fix 2: Disable PCIe/Ethernet Wakeups (Avoid "Jolting" the Driver)
Peripherals or network noise might be waking the system before the GPU is ready.
```bash
# Add to /etc/tmpfiles.d/disable-usb-wake.conf (extending the existing fix)
w /proc/acpi/wakeup - - - - PEG1
w /proc/acpi/wakeup - - - - PXSX
w /proc/acpi/wakeup - - - - RP02
w /proc/acpi/wakeup - - - - RP03
w /proc/acpi/wakeup - - - - RP21
```

### Fix 3: BIOS Settings (Hardware Support)
1. **Enable Resizable BAR:** This improves VRAM management and is highly recommended for RTX 30 series cards.
2. **Verify "Above 4G Decoding" is Enabled:** Required for Resizable BAR.

### Fix 4: Force Re-generation of Initramfs
Ensure all `modprobe` options are baked into the boot image.
```bash
sudo mkinitcpio -P
```

## Question for User
Does your monitor use DisplayPort or HDMI? High-refresh DisplayPort monitors are notoriously picky about the "Hot Plug Detect" (HPD) signal during resume on NVIDIA.
