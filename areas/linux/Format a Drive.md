---
uid: 6e9779cd-8ff3-429d-b94a-69cce775434a
title: Format a Drive
kind: runbook
source: ""
date: ""
tags: [runbook, format, ext4, filesystem, storage, mkfs, fdisk, gdisk]
people: []
id: drive-format
aliases: []
related: []
---

# Facts and Requirements

- Target OS: Arch Linux and Debian (including Debian derivatives like Ubuntu)
- Covers local block storage devices: NVMe, SATA SSD/HDD, external USB drives
- **Destructive operation** — all existing data on the target partition is erased
- Covers two sub-workflows:
  - **Partition an unpartitioned disk** (create a GPT partition table + partition first)
  - **Format an existing partition** (target is already a partition like `/dev/sdb1`)
- `e2fsprogs` provides `mkfs.ext4` and is present by default on both distros

---

# Instructions

## Step 1: Install Required Tools

`e2fsprogs` (provides `mkfs.ext4`, `tune2fs`, `e2fsck`) ships pre-installed on
both Arch and Debian. Install `gdisk`/`fdisk` for partitioning if missing:

### Arch Linux

```bash
sudo pacman -S e2fsprogs gptfdisk
```

### Debian / Ubuntu

```bash
sudo apt update
sudo apt install e2fsprogs gdisk
```

---

## Step 2: Identify the Target Device

> [!CAUTION]
> Verify the device path carefully. Formatting the wrong device causes permanent
> data loss with no recovery path.

1. List all block devices:

   ```bash
   lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS
   ```

   Example output:

   ```text
   NAME        SIZE FSTYPE  LABEL      MOUNTPOINTS
   sda         1.8T
   └─sda1      1.8T ext4    OldData    /mnt/old
   sdb         500G
   nvme0n1   512G
   └─nvme0n1p1 512G ext4              /
   ```

2. Confirm the device is **not currently mounted**:

   ```bash
   findmnt /dev/sdb
   # No output = not mounted. Output = must unmount first.
   ```

3. If mounted, unmount before proceeding:
   ```bash
   sudo umount /dev/sdb1
   # Or, for the whole disk:
   sudo umount /dev/sdb*
   ```

---

## Step 3: Partition the Disk (skip if partition already exists)

If the target is a raw, unpartitioned disk (e.g. `/dev/sdb` with no children in
`lsblk`), create a GPT partition table and a single partition spanning the full disk.

> [!NOTE]
> If you just need to reformat an existing partition (e.g. `/dev/sdb1`), skip to
> **Step 4**.

### Using `gdisk` (recommended for GPT / UEFI systems)

```bash
sudo gdisk /dev/sdb
```

Interactive steps inside `gdisk`:

```
Command: o        # Create new GPT partition table (confirms: Y)
Command: n        # New partition
Partition number: 1
First sector:     (press Enter — accept default)
Last sector:      (press Enter — use entire disk)
Hex code:         8300   # Linux filesystem
Command: w        # Write changes and exit (confirms: Y)
```

> [!CAUTION]
> You can 'zap' the drive by going into the advanced options via 'x' and then
> using 'z'. This will clear the drive if there are partition, GPT or MBR issues

After exiting, verify the new partition was created:

```bash
lsblk /dev/sdb
# Expected: sdb -> sdb1
```

### Using `fdisk` (alternative, also GPT-capable)

```bash
sudo fdisk /dev/sdb
```

Interactive steps inside `fdisk`:

```
Command: g        # Create new GPT partition table
Command: n        # New partition
Partition number: 1
First sector:     (Enter — accept default)
Last sector:      (Enter — use full disk)
Command: w        # Write and exit
```

---

## Step 4: Format the Partition as ext4

Format the partition (e.g. `/dev/sdb1`). Adjust the label (`-L`) to suit your
use case — it shows up in file managers and `lsblk -f`.

### Basic format (no label)

```bash
sudo mkfs.ext4 /dev/sdb1
```

### Format with a label (recommended)

```bash
sudo mkfs.ext4 -L "MyDrive" /dev/sdb1
```

### Format with a label and reserved-blocks tuning

By default, ext4 reserves 5% of space for root. On large data drives this wastes
significant space. Set reserved blocks to 1% (or 0% for non-root drives):

```bash
sudo mkfs.ext4 -L "MyDrive" -m 1 /dev/sdb1
```

`mkfs.ext4` will print a summary of what it wrote, e.g.:

```text
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 122096645 4k blocks and 30531584 inodes
Filesystem UUID: e2a8934d-8422-424a-9ef1-bc290f6b4028
...
Writing superblocks and filesystem accounting information: done
```

---

## Step 5: Verify the Format

1. Confirm filesystem type and UUID were written correctly:

   ```bash
   sudo blkid /dev/sdb1
   # Expected: TYPE="ext4" and a UUID= field
   ```

2. Run an integrity check on the freshly-created filesystem:

   ```bash
   sudo e2fsck -f /dev/sdb1
   # Expected: "clean, N/M files, N/M blocks"
   ```

3. (Optional) Inspect filesystem parameters:
   ```bash
   sudo tune2fs -l /dev/sdb1 | grep -E "Filesystem (UUID|state|volume|features)|Reserved block|Block (count|size)"
   ```

---

## Step 6: Set Ownership After Mounting

Native Linux filesystems (ext4, btrfs, xfs) store POSIX permissions in disk
metadata. A freshly-formatted ext4 partition defaults to `root:root 0755`. Mount
it, then change ownership so your regular user can write to it.

```bash
# Mount temporarily to set ownership
sudo mkdir -p /mnt/mydrive
sudo mount /dev/sdb1 /mnt/mydrive

# Transfer ownership to your user
sudo chown -R "$USER":"$USER" /mnt/mydrive

# Unmount once done (or leave mounted and follow the fs-mount runbook for fstab)
sudo umount /mnt/mydrive
```

> [!TIP]
> To make the mount persistent across reboots, follow the **fs-mount** runbook
> (available via `navi` → "Runbook: Mount Filesystem Devices").

---

## Troubleshooting & Common Pitfalls

### 1. `mkfs.ext4: Device or resource busy`

- **Cause:** The partition or a partition on the same disk is still mounted.
- **Remedy:**
  ```bash
  lsof /dev/sdb1        # Show processes with the device open
  sudo umount /dev/sdb1
  ```

### 2. Partition not visible after `gdisk`/`fdisk`

- **Cause:** Kernel partition table cache is stale.
- **Remedy:** Force a re-read without rebooting:
  ```bash
  sudo partprobe /dev/sdb
  # Or:
  sudo blockdev --rereadpt /dev/sdb
  lsblk /dev/sdb
  ```

### 3. `e2fsck` reports errors on a brand-new filesystem

- **Cause:** Rarely happens, but can indicate a failing drive (bad sectors during
  `mkfs.ext4`).
- **Remedy:** Check drive health with SMART before trusting it with data:
  ```bash
  sudo smartctl -a /dev/sdb
  ```

### 4. Large drive shows only part of its capacity

- **Cause:** Old MBR partition table limits partitions to ~2 TiB. GPT is required
  for drives larger than 2 TiB.
- **Remedy:** Wipe and repartition with `gdisk` (GPT). Verify with:
  ```bash
  sudo gdisk -l /dev/sdb | head -5
  # "GPT: present" confirms GPT is in use
  ```
