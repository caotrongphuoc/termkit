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

[aliases]
enabled=false             # source configs/aliases.sh on shell start
```

> **Note:** Values for `theme.name`, `font.name`, and `logo.file` are basenames without extension — termkit appends the right extension based on shell / file type.

---

## II. What apply does

### 1. shell=bash

- Backs up `~/.bashrc` to `~/.bashrc.termkit.bak` on the first run.
- Appends a managed block that sources the theme, prints the logo, and sources aliases.

### 2. shell=zsh

- Same as bash, but writes to `~/.zshrc` and `~/.zshrc.termkit.bak`.
- If the theme is a `.zsh-theme` file, copies it to `~/.oh-my-zsh/custom/themes/<name>.zsh-theme` and reminds you to set `ZSH_THEME=<name>` yourself. Standalone `.zsh` themes are sourced from the managed block directly.

### 3. Common to both

- Re-running `apply` strips the old managed block and writes a new one — never stacks duplicates.
- If `[font] install=true`, the `.ttf` is copied to `~/.local/share/fonts/` and `fc-cache -f` runs.
- Anything else in your shell rc is left alone.

---

## III. Managed block markers

Termkit only writes between these two lines. Anything above `# >>> termkit start >>>` and below `# <<< termkit end <<<` is your own.

```
# >>> termkit start >>>
# ...
# <<< termkit end <<<
```
