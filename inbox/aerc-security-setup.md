---
uid: 98f83b14-9b47-4799-bc57-905a1794a5b0
title: aerc-security-setup
kind: "runbook"
source: ""
date: "2026-11-07"
tags: ["mail", "aerc", "security", "gpg"]
people: []
related: []
---
# Hardened aerc Setup Runbook (Gmail)

A comprehensive, operational guide for running `aerc` securely with Gmail on Arch Linux using Google App Passwords, GPG-encrypted credentials, and network-isolated HTML rendering. All files live exclusively in `~/.config/aerc/` (kept independent of dotfiles/git).

---

## Part 1: Security Posture & Architecture

1. **Zero Plaintext Secrets on Disk**: Passwords are never written to `accounts.conf`. `aerc` queries `gpg` dynamically in memory at connection time via `gpg-agent` (already hooked into your shell via `export GPG_TTY=$(tty)`).
2. **Encrypted In-Transit**: Direct `imaps://` (port 993) and `smtps://` (port 465) enforce strict TLS encryption.
3. **No Local Mail Cache**: Mail stays on the IMAP server; no unencrypted maildir or plaintext emails reside on disk.
4. **Strict Permission Boundary**: `accounts.conf` is locked to `0600` (read/write only by file owner).
5. **Network-Isolated HTML Rendering**: HTML emails are parsed through `w3m` inside a restricted network namespace (`unshare --net`) via `/usr/lib/aerc/filters/html`, neutralizing tracking pixels and remote image beacons.

---

## Part 2: Prerequisites & Package Verification

Ensure required system utilities are installed:

```bash
sudo pacman -S aerc gnupg w3m
```

---

## Part 3: Step-by-Step Provisioning

### Step 1: Generate Google App Password
1. Navigate to [Google Account Security](https://myaccount.google.com/security).
2. Ensure **2-Step Verification** is active.
3. Search for **"App passwords"** in the top search bar.
4. Create an entry:
   - App name: `aerc`
5. Copy the 16-character string (spaces can be omitted).

---

### Step 2: Encrypt Credentials with GPG

1. **Verify or create a GPG key**:
   ```bash
   gpg --list-secret-keys --keyid-format LONG
   ```
   *If generating fresh:*
   ```bash
   gpg --full-generate-key
   ```
   - **Recommended Type**: `(9) ECC (sign and encrypt)` -> `(1) Curve 25519`
   - **Expiration**: `1y` / `2y` or `0` (no expiration)
   - **Email**: `tylerkilburn@gmail.com`

2. **Store encrypted app password**:
   ```bash
   mkdir -p ~/.local/share/aerc
   echo "YOUR-16-CHAR-APP-PASSWORD" | gpg --encrypt -r "tylerkilburn@gmail.com" -o ~/.local/share/aerc/gmail.gpg
   ```

3. **Verify decryption**:
   ```bash
   gpg --batch --quiet --decrypt ~/.local/share/aerc/gmail.gpg
   ```
   *Must output the 16-character string directly to the terminal.*

---

### Step 3: Configure `~/.config/aerc/`

1. **Create config directory**:
   ```bash
   mkdir -p ~/.config/aerc
   ```

2. **Configure `~/.config/aerc/accounts.conf`**:
   ```ini
   [Personal]
   source = imaps://tylerkilburn%40gmail.com@imap.gmail.com:993
   source-cred-cmd = gpg --batch --quiet --decrypt ~/.local/share/aerc/gmail.gpg

   outgoing = smtps://tylerkilburn%40gmail.com@smtp.gmail.com:465
   outgoing-cred-cmd = gpg --batch --quiet --decrypt ~/.local/share/aerc/gmail.gpg

   default = INBOX
   from = "Tyler Kilburn" <tylerkilburn@gmail.com>
   copy-to = [Gmail]/Sent Mail
   postpone = [Gmail]/Drafts
   archive = [Gmail]/All Mail
   check-mail = 1m
   ```

3. **Apply strict file permissions**:
   ```bash
   chmod 600 ~/.config/aerc/accounts.conf
   ```

4. **Verify `~/.config/aerc/aerc.conf` (Viewer & Filters)**:
   Ensure viewer preferences favor plaintext and pipe HTML safely:
   ```ini
   [viewer]
   pager = less -R
   alternatives = text/plain,text/html

   [filters]
   text/plain = colorize
   text/html = /usr/lib/aerc/filters/html
   text/calendar = /usr/lib/aerc/filters/calendar
   message/delivery-status = colorize
   message/rfc822 = colorize
   ```

---

## Part 4: Operations & Verification

### 1. Test and Launch
```bash
aerc
```

### 2. Common Keybindings
| Action | Key |
| :--- | :--- |
| Move up / down | `k` / `j` |
| Open message | `Enter` or `l` |
| Close viewer / return to list | `q` or `h` |
| Compose new message | `C` |
| Reply / Reply-all | `r` / `R` |
| Archive message | `a` |
| Delete message | `d` |
| Next / prev folder tab | `J` / `K` |
| Command prompt / quit | `:quit` |

---

## Part 5: Troubleshooting

- **Authentication Failed (`AUTHENTICATIONFAILED`)**:
  - Test credential output: `gpg --batch --quiet --decrypt ~/.local/share/aerc/gmail.gpg`
  - Ensure the decrypted output has no trailing unwanted whitespace or newline variations.
  - Verify IMAP is enabled in Gmail settings (`Settings -> Forwarding and POP/IMAP -> Enable IMAP`).
- **GPG Pinentry prompts in wrong terminal**:
  - Run `export GPG_TTY=$(tty)` and `gpg-connect-agent updatestartuptty /bye >/dev/null`.
- **Permission errors on startup**:
  - Run `chmod 600 ~/.config/aerc/accounts.conf`.
