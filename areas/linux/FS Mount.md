---
uid: d61b18ea-af15-49a9-80aa-0416238ddf69
title: FS Mount
kind: runbook
source: ""
date: ""
tags: [runbook, mount, storage, fstab, systemd]
people: []
id: fs-mount
aliases: []
related: []
---

# Facts and Requirements

- Target OS: Arch Linux and Debian (including Debian derivatives like Ubuntu)
- Covers local block storage devices: NVMe, SATA SSD/HDD, external USB drives
- Supported filesystems: `ext4`, `btrfs`, `xfs`, `ntfs-3g`, `exfat`
- Methodologies:
  - **Manual Mounting**: Temporary mounts via `mount` and `umount`
  - **Automatic Mounting**: Persistent boot mounting via `/etc/fstab` using persistent UUIDs
  - **On-Demand Automounting**: Dynamic mounting on access using `x-systemd.automount`
- Emphasizes safe validation workflows (`mount -a`, `systemctl daemon-reload`) to avoid boot hangs or emergency shells

---

# Instructions

## Step 1: Install Filesystem Utilities

Core block device utilities (`lsblk`, `blkid`, `findmnt`, `mount`, `umount`) are part of `util-linux` and pre-installed on both distributions. Install filesystem-specific drivers as needed:

### Arch Linux
```bash
# ext4 is included by default; install btrfs, xfs, ntfs, and exfat support:
sudo pacman -S btrfs-progs xfsprogs ntfs-3g exfatprogs
```

### Debian / Ubuntu
```bash
# ext4 is included by default; install btrfs, xfs, ntfs, and exfat support:
sudo apt update
sudo apt install btrfs-progs xfsprogs ntfs-3g exfatprogs
```

---

## Step 2: Identify Device and Persistent Identifier (UUID)

Linux assigns transient device names like `/dev/sdb1` or `/dev/nvme1n1p1` which can change across reboots or when USB devices are plugged in different ports. **Always identify devices by UUID or PARTUUID.**

1. List all block devices, their filesystem type, label, and mount point:
   ```bash
   lsblk -f
   ```
   Or for detailed column output:
   ```bash
   lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS
   ```

2. Alternatively, inspect via `blkid` (requires root privileges for full partition cache):
   ```bash
   sudo blkid
   ```
   *Example output:*
   ```text
   /dev/sdb1: LABEL="Storage" UUID="e2a8934d-8422-424a-9ef1-bc290f6b4028" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="0e7b415a-01"
   /dev/sdc1: LABEL="Backup" UUID="9B7C-A58F" BLOCK_SIZE="512" TYPE="exfat" PARTUUID="45a27891-01"
   ```

3. Note down the **UUID** and **TYPE** of the partition you wish to mount.

---

## Step 3: Create Mount Point and Understand Permissions

Create the destination directory where the filesystem will be attached:

```bash
# Common conventions: /mnt/<name> or /media/<user>/<name>
sudo mkdir -p /mnt/storage
```

### Critical Gotcha: POSIX vs. Non-POSIX Permissions

- **Native Linux Filesystems (`ext4`, `btrfs`, `xfs`):**
  Linux permissions and ownership are stored inside the filesystem metadata on the disk itself. Passing mount options like `uid=`, `gid=`, or `umask=` is **not supported** by ext4/xfs. Instead, mount the filesystem first, then change directory ownership on the mount root:
  ```bash
  sudo chown -R $USER:$USER /mnt/storage
  chmod 755 /mnt/storage
  ```

- **Non-POSIX Filesystems (`exFAT`, `NTFS`, `FAT32`):**
  These filesystems do not understand POSIX users and permissions. Ownership and permissions must be assigned at mount time via mount options (`uid`, `gid`, `umask`):
  ```bash
  # Check your UID and GID (typically 1000 on single-user systems):
  id -u
  id -g
  ```

---

## Step 4: Manual Mounting and Unmounting

### 4.1 Manual Mount Syntax

Mount using the persistent device symlink under `/dev/disk/by-uuid/<UUID>`:

- **ext4 / xfs:**
  ```bash
  sudo mount -t ext4 /dev/disk/by-uuid/e2a8934d-8422-424a-9ef1-bc290f6b4028 /mnt/storage
  ```

- **btrfs (default / top-level volume):**
  ```bash
  sudo mount -t btrfs /dev/disk/by-uuid/<UUID> /mnt/storage
  ```

- **btrfs (specific subvolume, e.g. `@data`):**
  ```bash
  sudo mount -t btrfs -o subvol=@data /dev/disk/by-uuid/<UUID> /mnt/storage
  ```

- **NTFS (read/write via ntfs-3g):**
  ```bash
  sudo mount -t ntfs-3g -o uid=1000,gid=1000,umask=022,windows_names /dev/disk/by-uuid/<UUID> /mnt/storage
  ```

- **exFAT:**
  ```bash
  sudo mount -t exfat -o uid=1000,gid=1000,umask=022 /dev/disk/by-uuid/<UUID> /mnt/storage
  ```

### 4.2 Verify the Active Mount

```bash
# View active mount details
findmnt /mnt/storage

# Check disk space and mount point
df -hT /mnt/storage
```

### 4.3 Safe Unmounting

```bash
sudo umount /mnt/storage
```

#### Troubleshooting Busy Mounts ("target is busy"):
If unmounting fails because the filesystem is in use:
```bash
# Find processes accessing the mount point
fuser -vm /mnt/storage
# Or with lsof:
lsof +f -- /mnt/storage

# If a process is stuck and blocking a clean unmount:
# Lazy unmount (detaches filesystem immediately, cleans up when references close)
sudo umount -l /mnt/storage
```

---

## Step 5: Automatic Mounting via `/etc/fstab`

`/etc/fstab` (File Systems Table) controls persistent mounts at system boot.

### 5.1 Structure of an `/etc/fstab` Entry

Each entry contains six fields separated by whitespace:
```text
<file system>    <mount point>    <type>    <options>    <dump>    <pass>
```

1. `<file system>`: `UUID=<UUID>` (Recommended) or `PARTUUID=<PARTUUID>`.
2. `<mount point>`: Absolute target path (e.g. `/mnt/storage`).
3. `<type>`: Filesystem driver (`ext4`, `btrfs`, `xfs`, `ntfs-3g`, `exfat`).
4. `<options>`: Comma-separated mount flags (no spaces!).
5. `<dump>`: `0` (backup dump flag; practically obsolete, keep `0`).
6. `<pass>`: `fsck` order at boot:
   - `1` = Root filesystem (`/`)
   - `2` = Other local filesystems needing check (`ext4`, `xfs`)
   - `0` = Disable fsck check (mandatory for `btrfs`, `ntfs-3g`, `exfat`, and network drives)

### 5.2 Backup `/etc/fstab` Before Editing
```bash
sudo cp /etc/fstab /etc/fstab.bak
```

### 5.3 Recommended `/etc/fstab` Templates

Open `/etc/fstab` with root permissions:
```bash
sudo vim /etc/fstab
```

#### Profile A: Internal Secondary SSD / HDD (ext4 or xfs)
Mounts automatically on boot. Includes `nofail` so a missing or failing secondary drive does not prevent the system from booting into userspace.
```fstab
# Internal ext4 storage
UUID=e2a8934d-8422-424a-9ef1-bc290f6b4028  /mnt/storage  ext4  defaults,noatime,nofail  0  2

# Internal XFS storage
UUID=a4c92110-18f4-411a-8bb4-09927efac901  /mnt/data     xfs   defaults,noatime,nofail  0  2
```
- `defaults`: Includes `rw`, `suid`, `dev`, `exec`, `auto`, `nouser`, and `async`.
- `noatime`: Disables writing file access timestamps (improves SSD/HDD I/O performance).
- `nofail`: Does not halt system startup or trigger emergency recovery if the device is disconnected or missing.

#### Profile B: Btrfs Volume (with Subvolume and Compression)
```fstab
# Btrfs data partition with zstd compression and subvolume
UUID=7b801a2f-e877-4c3e-9081-306917637841  /mnt/btrfs-data  btrfs  defaults,noatime,compress=zstd:3,subvol=@data,nofail  0  0
```

#### Profile C: External USB Drive / Removable Media (On-Demand systemd Automount)
Using `x-systemd.automount` creates a systemd automount unit. The partition is **not** mounted at boot time; instead, the kernel mounts it the instant any process accesses the directory path `/mnt/usb-backup`.
```fstab
# External USB ext4 drive: automount on directory access, unmount after 10 min idle
UUID=3d1789c0-9512-4aa3-8a30-671295b927a4  /mnt/usb-backup  ext4  defaults,noauto,nofail,x-systemd.automount,x-systemd.device-timeout=5,x-systemd.idle-timeout=10min  0  0
```
- `noauto`: Do not mount during the early boot sequence.
- `x-systemd.automount`: Mount dynamically when `/mnt/usb-backup` is accessed.
- `x-systemd.device-timeout=5`: Fail quickly (5s) if the drive is unplugged rather than hanging for the default 90s.
- `x-systemd.idle-timeout=10min`: Automatically unmount the drive after 10 minutes of inactivity.

#### Profile D: Windows Shared Drive (NTFS)
```fstab
# Shared Windows partition (ntfs-3g)
UUID=4AF889F1F889DB0D  /mnt/windows  ntfs-3g  defaults,nofail,uid=1000,gid=1000,umask=022,windows_names  0  0
```

#### Profile E: External exFAT Drive
```fstab
# exFAT external drive with on-demand automount
UUID=64F2-3B21  /mnt/exfat-drive  exfat  defaults,noauto,nofail,uid=1000,gid=1000,umask=022,x-systemd.automount,x-systemd.device-timeout=5  0  0
```

---

## Step 6: Validate `/etc/fstab` Before Rebooting

> [!CAUTION]
> Never reboot immediately after modifying `/etc/fstab`. A syntax error or incorrect UUID can force your machine into emergency recovery mode.

1. Tell systemd to re-read unit configurations generated from `/etc/fstab`:
   ```bash
   sudo systemctl daemon-reload
   ```

2. Test mount all filesystems defined in `/etc/fstab`:
   ```bash
   sudo mount -a -v
   ```
   *If this command exits cleanly without errors, the configuration syntax and UUIDs are valid.*

3. If using `x-systemd.automount`:
   Restart the automount target or inspect the generated systemd unit:
   ```bash
   # Systemd automatically creates a unit named after the escaped mount path
   # e.g., /mnt/usb-backup becomes mnt-usb\x2dbackup.automount
   systemctl list-unit-files --type=automount

   # Trigger the automount by accessing the directory:
   ls /mnt/usb-backup

   # Check active mount state:
   findmnt /mnt/usb-backup
   ```

---

## Troubleshooting & Common Pitfalls

### 1. System Drops to Emergency Mode on Boot
- **Symptom:** Startup hangs at `A start job is running for /dev/disk/by-uuid/...` or drops into emergency maintenance mode.
- **Cause:** A drive listed in `/etc/fstab` is disconnected, powered down, or its UUID changed, and it lacks the `nofail` flag.
- **Remedy:**
  1. Enter root password in emergency shell.
  2. Remount root filesystem as read/write:
     ```bash
     mount -o remount,rw /
     ```
  3. Edit `/etc/fstab` and add `nofail` to the offending line, or comment it out with `#`.
  4. Run `systemctl daemon-reload && reboot`.

### 2. Read-Only Mount on NTFS ("Filesystem is dirty")
- **Cause:** Windows Fast Startup or Hibernation leaves NTFS partitions in a locked/dirty state.
- **Remedy:**
  - In Windows: Disable "Turn on fast startup" in Control Panel Power Options.
  - In Linux: Attempt a non-destructive repair check:
    ```bash
    sudo ntfsfix /dev/disk/by-uuid/<UUID>
    ```

### 3. Permission Denied on ext4/btrfs Mounts for Normal Users
- **Cause:** Ext4/Btrfs partitions default to `root:root` with `0755` permissions upon creation.
- **Remedy:** Mount the filesystem, then run:
  ```bash
  sudo chown -R $(id -un):$(id -gn) /mnt/storage
  ```
