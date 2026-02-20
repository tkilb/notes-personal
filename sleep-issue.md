---
id: sleep-issue
aliases: []
tags: []
---

1. Check Gnome Power Settings

# Check current power settings

gsettings get org.gnome.settings-daemon.plugins.power
sleep-inactive-ac-timeout
gsettings get org.gnome.settings-daemon.plugins.power
sleep-inactive-battery-timeout

2. Check systemd sleep/suspend settings

# Check lid switch behavior

cat /etc/systemd/logind.conf | grep -i "idle"

# Check what's triggering the sleep

journalctl -b -u systemd-logind | tail -50

3. Monitor what's happening when it goes back to sleep

# Watch system logs in real-time after waking

journalctl -f

4. Check for idle timeout settings

# Check systemd idle settings

systemctl show systemd-logind.service | grep -i idle

Common Causes & Fixes:

Most likely culprit: Gnome's automatic suspend setting is probably set to
15-20 minutes, but there may be an issue where it thinks the system has been
idle.

Fix attempt 1 - Disable auto-suspend:

gsettings set org.gnome.settings-daemon.plugins.power
sleep-inactive-ac-timeout 0
gsettings set org.gnome.settings-daemon.plugins.power
sleep-inactive-battery-timeout 0

Fix attempt 2 - Check systemd idle action:

# Edit logind.conf

sudo nano /etc/systemd/logind.conf

# Ensure these lines are set or uncommented:

IdleAction=ignore
IdleActionSec=0

# Then restart logind

sudo systemctl restart systemd-logind

Would you like me to create a diagnostic script you can run on your Arch
machine to gather all this information at once?

```

```

```

```

1. Check Gnome Power Settings

# Check current power settings

gsettings get org.gnome.settings-daemon.plugins.power
sleep-inactive-ac-timeout
gsettings get org.gnome.settings-daemon.plugins.power
sleep-inactive-battery-timeout

2. Check systemd sleep/suspend settings

# Check lid switch behavior

cat /etc/systemd/logind.conf | grep -i "idle"

# Check what's triggering the sleep

journalctl -b -u systemd-logind | tail -50

3. Monitor what's happening when it goes back to sleep

# Watch system logs in real-time after waking

journalctl -f

4. Check for idle timeout settings

# Check systemd idle settings

systemctl show systemd-logind.service | grep -i idle

Common Causes & Fixes:

Most likely culprit: Gnome's automatic suspend setting is probably set to
15-20 minutes, but there may be an issue where it thinks the system has been
idle.

Fix attempt 1 - Disable auto-suspend:

gsettings set org.gnome.settings-daemon.plugins.power
sleep-inactive-ac-timeout 0
gsettings set org.gnome.settings-daemon.plugins.power
sleep-inactive-battery-timeout 0

Fix attempt 2 - Check systemd idle action:

# Edit logind.conf

sudo nano /etc/systemd/logind.conf

# Ensure these lines are set or uncommented:

IdleAction=ignore
IdleActionSec=0

# Then restart logind

sudo systemctl restart systemd-logind

Would you like me to create a diagnostic script you can run on your Arch
machine to gather all this information at once?
