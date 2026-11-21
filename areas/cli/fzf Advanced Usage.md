---
uid: 808198f5-a95a-416d-bd15-0d358ecd414c
title: fzf Advanced Usage
kind: guide
source: ""
date: ""
tags: []
people: []
related: []
---
# Runbook: Advanced fzf usage

## Shell integration key bindings

These come from `fzf --zsh` (sourced in `zsh/.feature.fzf.sh`):

- `Ctrl-T` - fuzzy-find a file/dir under the cwd, insert path at cursor
- `Ctrl-R` - fuzzy-search shell history, insert selected command
- `Alt-C` - fuzzy-find a directory under the cwd, `cd` into it
- `Tab` (after typing a command + partial path) - fzf-powered path completion,
  e.g. `vim **<Tab>`

## Multi-select

- `Tab` marks/unmarks the item under the cursor and moves down
- `Shift-Tab` marks/unmarks and moves up
- `Ctrl-A` (inside fzf) selects all visible items
- Marked items are printed one per line on accept - combine with `xargs`:
  `fzf --multi | xargs -I{} echo {}`

## Preview window

- `--preview '<cmd>'` runs `<cmd>` with `{}` substituted for the current
  selection, e.g. `fzf --preview 'bat --color=always {}'`
- `--preview-window` controls layout/size, e.g. `right:60%`, `up:40%:wrap`,
  `hidden` (toggle with a bound key instead of always showing)
- `?` is a common custom binding (via `--bind`) to toggle preview visibility:
  `fzf --preview 'bat {}' --bind '?:toggle-preview'`

## Filtering syntax (fzf's own fuzzy query language)

Typed directly into the fzf prompt, not a shell feature:

- `sbtrkt` - fuzzy match containing those chars in order
- `'wild` - exact substring match (leading `'`)
- `^music` - prefix match (line must start with `music`)
- `.mp3$` - suffix match (line must end with `.mp3`)
- `!fire` - inverse match (exclude lines containing `fire`)
- `src | test` - OR - match either term
- Combine terms with spaces for AND, e.g. `^src .go$ !vendor`

## Bindings (`--bind`) for custom keymaps

- `--bind 'ctrl-y:execute-silent(echo {} | pbcopy)'` - copy selection to
  clipboard without leaving fzf
- `--bind 'ctrl-e:execute($EDITOR {} < /dev/tty > /dev/tty)'` - open selection
  in `$EDITOR`, suspending fzf while it runs
- `--bind 'ctrl-/:change-preview-window(hidden|)'` - cycle preview window
  states
- Multiple binds are comma-separated in one `--bind` flag or repeated
  `--bind` flags

## Combining with other tools

- `fd --type f --hidden --exclude .git | fzf` - fzf as the picker, `fd` as a
  faster/gitignore-aware source than the shell's default walker
- `rg --files-with-matches "<pattern>" | fzf` - fuzzy-narrow ripgrep's
  matched files before opening one
- `fzf --ansi` - preserve ANSI color codes in input (needed when piping from
  tools like `rg --color=always` or `eza --color=always`)
- `git log --oneline --color=always | fzf --ansi --preview 'git show --color=always {1}'`
  - browse commits with a live diff preview

## Environment variables worth knowing

- `FZF_DEFAULT_OPTS` - global default flags applied to every fzf invocation
  (e.g. `export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'`)
- `FZF_DEFAULT_COMMAND` - overrides the default file source fzf uses when no
  input is piped in (e.g. `fd --type f`)
- `FZF_CTRL_T_COMMAND` / `FZF_ALT_C_COMMAND` - override the source command
  used specifically by the `Ctrl-T` / `Alt-C` shell-integration widgets
- `FZF_CTRL_T_OPTS` / `FZF_CTRL_R_OPTS` / `FZF_ALT_C_OPTS` - extra fzf flags
  (e.g. custom preview) applied only to that specific widget
