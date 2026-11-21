---
uid: eb2f4a7a-4012-4261-a93a-be7b152121c9
title: NAS ZFS Recovery
kind: runbook
source: ""
date: ""
tags: []
people: []
related: []
---
# ZFS Snapshot & Disaster Recovery Runboo#

## Part 1: Scheduling & Creating Snapshots

### 1. Automated Schedules (Hourly, Daily, Monthly)

`sanoid` manages schedules via atomic retention counters. To handle weekly targets without scheduler conflicts, best practice is to maintain a rolling daily retention block (e.g., keeping 30 days covers all weeks).

#### A. Configure the Policy

Open your configuration file:

```bash
sudo nano /etc/sanoid/sanoid.conf
```

Paste this configuration template:

```ini
[template_production]
    hourly = 24          # Keep every hour for 1 day
    daily = 30           # Keep every day for 1 month (covers weekly needs)
    monthly = 3          # Keep every month for one quarter
    yearly = 0
    autosnap = yes
    autoprune = yes

# Apply globally to your pool and all its child datasets
[tank]
    use_template = template_production
    recursive = yes
```

#### B. Activate the Automation Engine

Arm the native systemd timer to check your configuration and process snapshots every 15 minutes:

```bash
sudo systemctl enable --now sanoid.timer
```

---

### 2. Creating Manual Snapshots (Ad-hoc Backups)

Before running major updates, migrations, or risky script executions, manually generate a point-in-time snapshot. It is highly recommended to append a standardized identifier like `@manual_` followed by the date or purpose.

- **Snapshot a single dataset:**
  ```bash
  sudo zfs snapshot tank/documents@manual_before_update_2026-09-08
  ```
- **Snapshot a dataset and all of its child datasets recursively (`-r`):**
  Use this if your main dataset houses nested child filesystems (like Docker volumes or home directories) that must be captured at the exact same atomic transaction state.
  ```bash
  sudo zfs snapshot -r tank@manual_pre_migration
  ```

---

## Part 2: Monitoring & Listing Active Snapshots

### 1. List All Active Snapshots (Chronological Order)

```bash
zfs list -t snapshot -o name,creation -s creation
```

### 2. Check Space Allocated strictly to Snapshots

```bash
zfs list -t snapshot -o name,used,referenced,creation
```

### 3. Verify the Scheduling Service Status

```bash
systemctl list-timers sanoid.timer
```

---

## Part 3: Disaster Recovery & Data Access Scenarios

### Scenario A: Surgical Recovery (Hidden `.zfs` Directory)

ZFS exposes a read-only, hidden folder at the root of every dataset mount point. **You do not need to take your dataset offline or mount anything manually to grab old files.**

1. Change directory directly into the hidden folder at your dataset's mountpoint:
   ```bash
   cd /path/to/dataset/.zfs/snapshot/
   ```
2. Run `ls` to view historical snapshot directories, navigate inside, and use standard tools like `cp` or `rsync` to pull files back to the live environment.

---

### Scenario B: Mounting a Snapshot Independently (Cloning)

If you need to mount a snapshot to a custom directory (e.g., to run a backup script, inspect a massive historical state, or share a static copy over the network without modifying live data), you cannot mount a raw snapshot directly. ZFS best practice dictates **cloning the snapshot into a temporary dataset**, which can then be mounted anywhere.

1. **Find your target snapshot**:
   ```bash
   zfs list -t snapshot
   ```
2. **Clone the snapshot** into a temporary workspace dataset:
   ```bash
   sudo zfs clone tank/documents@autosnap_2026-09-08_12:00:00_hourly tank/temp-recovery
   ```
3. **Set a custom mountpoint** for your cloned dataset:
   ```bash
   sudo mkdir -p /mnt/recovery-workspace
   sudo zfs set mountpoint=/mnt/recovery-workspace tank/temp-recovery
   ```
4. **Inspect or use your data** at `/mnt/recovery-workspace`. Unlike the hidden `.zfs` directory, this clone is fully writable if you need to test changes safely.
5. **Clean up when finished**: Destroy the temporary clone and clean up the host directory once you are done with the recovery work.
   ```bash
   sudo zfs destroy tank/temp-recovery
   sudo rmdir /mnt/recovery-workspace
   ```

---

### Scenario C: Complete Dataset Rollback (The Nuclear Option)

If a critical dataset gets corrupted, you can wind back the clock to the exact moment a healthy snapshot was captured.

> ⚠️ **Warning:** A rollback permanently destroys all live changes made _after_ that snapshot was taken. If you use the recursive flag (`-r`), it will also permanently delete any newer snapshots taken between now and your targeted recovery point.

1. **Stop any services** accessing the dataset (like OMV SMB/NFS shares or Docker containers) to prevent file lockups:
   ```bash
   sudo systemctl stop docker
   ```
2. **Execute the rollback command**:
   ```bash
   sudo zfs rollback tank/documents@autosnap_2026-09-08_12:00:00_hourly
   ```
   _(Note: If newer snapshots exist after your target date, ZFS will block the action. Append the `-r` flag to recursively destroy newer snapshots if you are certain: `sudo zfs rollback -r tank/documents@snapshotname`)_.
3. **Restart your services**:
   ```bash
   sudo systemctl start docker
   ```

