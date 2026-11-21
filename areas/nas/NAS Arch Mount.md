---
uid: bad77c51-c6ed-4cc1-bc02-125ce2eda9b8
title: NAS Arch Mount
kind: runbook
source: ""
date: ""
tags: []
people: []
related: []
---
# NAS Mount Setup on Arch Linux

This configures the SMB/CIFS shares on `192.168.0.123`:

- `//192.168.0.123/d2` at `/mnt/nas/d2`
- `//192.168.0.123/d3` at `/mnt/nas/d3`

The shares use systemd automounting. They are mounted when first accessed,
and `_netdev` tells systemd that they require the network.

## Prerequisites

- NAS username and password
- An Arch Linux system
- `sudo` access

## Install CIFS utilities

```bash
sudo pacman -Syu cifs-utils
```

## Create the mount points

```bash
sudo install -d -o root -g root -m 0755 /mnt/nas /mnt/nas/d2 /mnt/nas/d3
```

## Create the SMB credentials file

Create the credentials directory with permissions that restrict access to root:

```bash
sudo install -d -o root -g root -m 0700 /etc/smb
sudoedit /etc/smb/credentials
```

Add the following content, replacing the placeholder values:

```text
username=your_nas_username
password=your_nas_password
```

Secure the file:

```bash
sudo chown root:root /etc/smb/credentials
sudo chmod 600 /etc/smb/credentials
```

## Add the mounts to `/etc/fstab`

Back up the existing file:

```bash
sudo cp /etc/fstab /etc/fstab.backup
```

Append these two entries to `/etc/fstab`:

```text
//192.168.0.123/d2  /mnt/nas/d2  cifs  credentials=/etc/smb/credentials,iocharset=utf8,file_mode=0777,dir_mode=0777,uid=1000,gid=1000,x-systemd.automount,_netdev  0  0
//192.168.0.123/d3  /mnt/nas/d3  cifs  credentials=/etc/smb/credentials,iocharset=utf8,file_mode=0777,dir_mode=0777,uid=1000,gid=1000,x-systemd.automount,_netdev  0  0
```

Edit the file with:

```bash
sudoedit /etc/fstab
```

The `uid=1000` and `gid=1000` options make the mounted files appear owned by
the local user and group with those IDs. Check the correct values with:

```bash
id -u
id -g
```

If either value is not `1000`, replace the corresponding option in both fstab
entries.

## Reload systemd and enable network mount preparation

```bash
sudo systemctl daemon-reload
sudo systemctl enable remote-fs-pre.target
```

## Remove legacy mount points

If the old mount points `/mnt/d2` or `/mnt/d3` exist, unmount them and remove
the directories:

```bash
sudo umount -l /mnt/d2
sudo umount -l /mnt/d3
sudo rmdir /mnt/d2
sudo rmdir /mnt/d3
```

`umount -l` and `rmdir` may report errors when the paths do not exist; that is
safe to ignore.

## Test the automounts

Reload the fstab configuration:

```bash
sudo mount -a
```

Access each share to trigger its automount:

```bash
ls /mnt/nas/d2
ls /mnt/nas/d3
```

Verify that both shares are mounted:

```bash
findmnt /mnt/nas/d2
findmnt /mnt/nas/d3
```

If authentication fails, check the username and password in
`/etc/smb/credentials`. If a mount fails during boot or access, inspect the
corresponding systemd units:

```bash
systemctl status mnt-nas-d2.automount mnt-nas-d2.mount
systemctl status mnt-nas-d3.automount mnt-nas-d3.mount
```
