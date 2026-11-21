---
uid: 8ba11679-8931-46ba-b1e6-7ab7fd9bf78c
title: NAS SSH
kind: runbook
source: ""
date: ""
tags: []
people: []
related: []
---
# Runbook: Setup SSH with Debian NAS (`pi-server`)

## Environment & Context

- **Workstation:** Arch Linux (`linux-box`)
- **NAS Server:** Debian 12 (Raspberry Pi / `pi-server`)
- **NAS IP Address:** `192.168.0.123` (identified from CIFS mounts at `/mnt/d2` and `/mnt/d3`)
- **SSH Port:** `22` (default)
- **Dedicated Key File:** `~/.ssh/id_nas`

---

## 1. Verify NAS Reachability

Ensure the NAS is responding on the local network and the SSH daemon is listening:

```bash
# Test network ping
ping -c 3 192.168.0.123

# Test SSH port connectivity
timeout 3 bash -c '</dev/tcp/192.168.0.123/22' && echo "SSH is up"
```

> **Note:** If SSH is not running on the Debian server yet, enable it directly on the NAS:
>
> ```bash
> sudo apt update && sudo apt install -y openssh-server
> sudo systemctl enable --now ssh
> ```

---

## 2. Generate a Dedicated ED25519 SSH Key Pair

Create an isolated ED25519 key pair specifically for accessing the NAS from this workstation:

```bash
ssh-keygen -t ed25519 -a 100 -C "tylerkilburn@linux-box - nas" -f ~/.ssh/id_nas
```

- When prompted for a passphrase, enter a passphrase (or press Enter if a passwordless key is preferred).
- Verify the generated files:
  ```bash
  ls -l ~/.ssh/id_nas*
  # Private key: ~/.ssh/id_nas (mode 0600)
  # Public key:  ~/.ssh/id_nas.pub (mode 0644)
  ```

---

## 3. Install the Public Key on the Debian NAS

### Option A: Using `ssh-copy-id` (Recommended)

Replace `<user>` with your remote username on the NAS (e.g. `linux-book` or `pi`):

```bash
ssh-copy-id -i ~/.ssh/id_nas.pub <user>@192.168.0.123
```

_Enter the remote user's password when prompted._

### Option B: Manual Installation (Fallback)

If `ssh-copy-id` is unavailable, stream the key over SSH directly:

```bash
cat ~/.ssh/id_nas.pub | ssh <user>@192.168.0.123 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

---

## 4. Configure `~/.ssh/config` on Arch Linux

Edit `~/.ssh/config` to add host aliases for quick access:

```bash
nvim ~/.ssh/config
```

Append the host entry:

```ssh-config
Host pi-server nas
    HostName 192.168.0.123
    User <user>
    IdentityFile ~/.ssh/id_nas
    IdentitiesOnly yes
```

Ensure permissions on `~/.ssh/config` are restrictive:

```bash
chmod 600 ~/.ssh/config
```

---

## 5. Test SSH Connection

Connect using either host alias:

```bash
ssh pi-server
# or
ssh nas
```

Verify you can log in without being prompted for the remote account password.

---

## 6. Security Hardening on Debian NAS (Optional)

Once key-based authentication is verified working, harden the OpenSSH daemon on the NAS:

1. SSH into the NAS:
   ```bash
   ssh pi-server
   ```
2. Create a drop-in configuration for OpenSSH (`/etc/ssh/sshd_config.d/99-hardening.conf`):
   ```bash
   sudo bash -c 'cat > /etc/ssh/sshd_config.d/99-hardening.conf << "EOF"
   PasswordAuthentication no
   PermitEmptyPasswords no
   PermitRootLogin prohibit-password
   PubkeyAuthentication yes
   X11Forwarding no
   EOF'
   ```
3. Test sshd configuration syntax before restarting:
   ```bash
   sudo sshd -t
   ```
4. Restart SSH service:
   ```bash
   sudo systemctl restart ssh
   ```
5. Keep your existing session open and test connecting in a new terminal window:
   ```bash
   ssh pi-server
   ```

---

## 7. Troubleshooting

- **Permission Denied (publickey):**
  Check directory and file permissions on the NAS:
  ```bash
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/authorized_keys
  chmod 755 ~
  ```
- **Known Hosts Conflict / Changed Key:**
  If the NAS was reinstalled and host key changed:
  ```bash
  ssh-keygen -R 192.168.0.123
  ```
- **Verbose Debugging:**
  Inspect SSH handshake and authentication negotiation in detail:
  ```bash
  ssh -v pi-server
  ```
