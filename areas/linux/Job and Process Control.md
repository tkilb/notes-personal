---
uid: 0c5644b0-a38c-44af-a0b1-aaf9b7e73545
title: Job and Process Control
kind: guide
source: ""
date: ""
tags: [runbook, job-control, suspend, jobs, signals, process]
people: []
id: job-control
aliases: [suspend]
related: []
---

# Facts and Requirements

- Target OS: Linux and macOS (identical behavior — both use standard POSIX
  job control via the shell and the same signals: `SIGTSTP`, `SIGSTOP`,
  `SIGCONT`)
- Covers: suspending a foreground process with `Ctrl-Z`, listing/managing
  suspended (stopped) jobs, resuming them in the foreground or background,
  and suspending/resuming processes that weren't started in the current
  shell session
- Job control is a shell feature (bash, zsh, etc.), not a kernel feature —
  it won't work in non-interactive scripts or shells without job control
  enabled

---

# Instructions

## Step 1: Suspend the Foreground Process

Press `Ctrl-Z` while a process is running in the foreground. This sends
`SIGTSTP` to the process, pausing it and returning control to the shell:

```text
$ sleep 100
^Z
[1]+  Stopped                 sleep 100
```

The process is now **stopped** (not terminated) — it holds no CPU time but
keeps its memory, open file descriptors, and process state.

## Step 2: List Suspended / Background Jobs

```bash
jobs
```

```text
[1]+  Stopped                 sleep 100
[2]-  Stopped                 vim notes.txt
```

- `+` marks the "current" job (the default target for `fg`/`bg` if no `%n`
  is given)
- `-` marks the "previous" job
- Use `jobs -l` to also show PIDs

## Step 3: Resume a Job

### Resume in the foreground (reattach to the terminal)
```bash
fg          # resumes the current (+) job
fg %1       # resumes job number 1
fg %vim     # resumes by matching command name
```

### Resume in the background (keeps running, doesn't reattach)
```bash
bg          # resumes the current (+) job in the background
bg %1       # resumes job number 1 in the background
```

> [!NOTE]
> `bg` only makes sense for jobs that don't need terminal input. A stopped
> `vim` resumed with `bg` will immediately re-suspend itself if it tries to
> read from the terminal.

## Step 4: Suspend/Resume a Process by PID (not just shell jobs)

Job control (`Ctrl-Z`, `jobs`, `fg`, `bg`) only works for processes started
in your *current* shell session. To suspend/resume any process by PID
(e.g. one started elsewhere, or a background daemon), send the raw signals
directly:

```bash
# Suspend (stop) a process — equivalent effect to Ctrl-Z
kill -STOP <PID>
kill -TSTP <PID>

# Resume a stopped process
kill -CONT <PID>
```

- `SIGSTOP` cannot be caught, blocked, or ignored by the process — it will
  always stop. `SIGTSTP` is the "polite" version sent by `Ctrl-Z` and *can*
  be caught/ignored by the process (rarely done).
- Verify state with `ps`:
  ```bash
  ps -o pid,stat,comm -p <PID>
  ```
  A `STAT` value containing `T` means the process is stopped (e.g. `T` or
  `TN`).

## Step 5: Confirm a Suspended Process Is Actually Paused

```bash
# Linux: check /proc status
cat /proc/<PID>/status | grep State
# State: T (stopped)

# macOS/Linux (both): ps STAT column
ps -o pid,ppid,stat,%cpu,comm -p <PID>
```

---

# Common Pitfalls

## 1. `Ctrl-Z` Suspends, It Does Not Kill
A stopped job still holds memory and resources. If you close the terminal
(and the shell isn't running `disown`/`nohup`'d jobs), the shell sends
`SIGHUP` to remaining jobs, which typically terminates them — stopped jobs
are *not* automatically safe from this.

## 2. `bg`'ing a TTY-Reading Program Re-Suspends It
Programs that read from stdin (editors, REPLs, `less`, etc.) will
re-suspend themselves with `SIGTTIN` when backgrounded and given a chance to
read input. Use `fg` instead, or redirect their stdin if you truly need
them backgrounded.

## 3. `SIGSTOP`/`SIGCONT` Bypass Job Control Bookkeeping
Sending `kill -STOP` to a process from a *different* shell (not the one
that launched it) stops the process, but that shell's `jobs` table won't
know about it — only `ps`/`/proc` will show the correct state. Use `fg`/`bg`
only for jobs the current shell is tracking; use `kill -CONT` for
processes managed elsewhere.

## 4. Multiple Jobs — Ambiguous `fg`/`bg` Targets
With more than one stopped job, plain `fg`/`bg` targets only the `+`
(current) job. Always specify `%<job-number>` when managing multiple
suspended processes to avoid resuming the wrong one.

## 5. macOS `ps` Flags Differ Slightly from GNU/Linux `ps`
macOS ships BSD `ps`; Linux typically ships GNU/procps `ps`. The `-o
pid,stat,comm -p <PID>` form used above works identically on both, but
other flags (e.g. `ps aux` vs `ps -ef`) can format columns differently.
