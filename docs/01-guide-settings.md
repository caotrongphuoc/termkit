<h1 align="center">Settings and apply behavior</h1>

This document describes the `configs/settings.conf` schema and what happens when `./install.sh apply` runs. Values are stored as `key=value` under `[sections]`; comments start with `#`.

---

## Table of Contents

- [I. Schema](#i-schema)
- [II. What apply does](#ii-what-apply-does)
  - [1. shell=bash](#1-shellbash)
  - [2. shell=zsh](#2-shellzsh)
  - [3. Common to both](#3-common-to-both)
- [III. Managed block markers](#iii-managed-block-markers)

---

## I. Schema

```
[shell]
name=bash                 # bash or zsh

[zsh]
plugins=                  # space-separated oh-my-zsh plugin names, or empty
                          # when non-empty (and shell=zsh), apply patches the
                          # plugins=(...) line in ~/.zshrc

[theme]
name=default              # basename of a file in configs/themes/<shell>/ (no extension)
                          # for bash: matches <name>.bash
                          # for zsh:  matches <name>.zsh (standalone) or <name>.zsh-theme (oh-my-zsh)

[font]
name=none                 # basename of a file in configs/fonts/*.ttf, or none
install=false             # copy the .ttf to ~/.local/share/fonts and refresh cache

[logo]
enabled=false             # print the logo on shell start
file=none                 # basename of a file in configs/logo/*.txt
use_fastfetch=false       # print via `fastfetch --logo` (falls back to `cat` if missing)

[fastfetch]
config=none               # basename of a file in configs/fastfetch/*.jsonc, or 'none'
                          # when set, apply overwrites ~/.config/fastfetch/config.jsonc

[aliases]
enabled=false             # source configs/aliases.sh on shell start
```

> **Note:** Values for `theme.name`, `font.name`, `logo.file`, and `fastfetch.config` are basenames without extension — Termkit appends the right extension based on shell / file type.

---

## II. What apply does

### 1. shell=bash

- Backs up `~/.bashrc` to `~/.bashrc.termkit.bak` on the first run.
- Appends a managed block that sources the theme, prints the logo, and sources aliases.

### 2. shell=zsh

- Same as bash, but writes to `~/.zshrc` and `~/.zshrc.termkit.bak`.
- If the theme is a `.zsh-theme` file, copies it to `~/.oh-my-zsh/custom/themes/<name>.zsh-theme` **and auto-patches `ZSH_THEME="<name>"` in `~/.zshrc`** (replaces the existing `ZSH_THEME=` line, or inserts one before the `source $ZSH/oh-my-zsh.sh` line). Standalone `.zsh` themes are sourced from the managed block directly.
- If `[zsh] plugins` is non-empty, **auto-patches `plugins=(...)` in `~/.zshrc`** the same way (replace or insert-before-source). Empty leaves the line alone.

### 3. Common to both

- Re-running `apply` strips the old managed block and writes a new one — never stacks duplicates.
- If `[font] install=true`, the `.ttf` is copied to `~/.local/share/fonts/` and `fc-cache -f` runs.
- If `[fastfetch] config` is not `none`, `configs/fastfetch/<name>.jsonc` is copied to `~/.config/fastfetch/config.jsonc` (overwrite, no backup). On uninstall, the file is removed only if its content still matches a shipped `.jsonc` byte-for-byte — local edits are left alone.
- Anything else in your shell rc is left alone.

---

## III. Managed block markers

Termkit only writes between these two markers. Anything above `# >>> termkit start >>>` and below `# <<< termkit end <<<` is your own.

```
# >>> termkit start >>>
# ...
# <<< termkit end <<<
```
