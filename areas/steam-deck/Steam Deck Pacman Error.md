---
uid: eee1c2fd-f683-4735-8575-df014c198c2e
title: Steam Deck Pacman Error
kind: runbook
source: adhoc
date: 2026-11-20
tags: []
people: []
related: []
---

## Error Symptom

```
error: failed to init transaction (unable to lock database)
error: could not lock database: Read-only file system
```

## Resolution

If you see the following error below, there are a few flags that need to be cleared

To make the read-only error go away immediately, run:

    sudo steamos-readonly disable

If a stale lockfile was left behind by the failed attempt, remove it:

    sudo rm -f /var/lib/pacman/db.lck

If pacman throws signature or keyring errors after disabling read-only mode, initialize the keyring:

    sudo pacman-key --init
    sudo pacman-key --populate archlinux holo

## Caveats

This most be reapplied whenever the steamdeck undergoes a major update.
