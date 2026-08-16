<h1 align="center">Settings and apply behavior</h1>

Schema of `configs/settings.conf` and what `./install.sh apply` does. Values are `key=value` under `[sections]`; comments start with `#`.

---

## Table of Contents

- [I. Schema](#i-schema)
- [II. What apply does](#ii-what-apply-does)
- [III. Managed block markers](#iii-managed-block-markers)

---

## I. Schema

```
[shell]
name=bash                 # bash or zsh

[zsh]
plugins=                  # space-separated oh-my-zsh plugin names
                          # non-empty (+ shell=zsh) → apply patches plugins=(...) in ~/.zshrc

[theme]
name=default              # basename of a file in configs/themes/<shell>/
                          # bash: <name>.bash; zsh: <name>.zsh or <name>.zsh-theme

[font]
name=none                 # basename of configs/fonts/*.ttf, or none
install=false             # copy to ~/.local/share/fonts + fc-cache

[logo]
enabled=false             # print the logo on shell start
file=none                 # basename of configs/logo/*.txt
use_fastfetch=false       # print via `fastfetch --logo` (falls back to cat)

[fastfetch]
config=none               # basename of configs/fastfetch/*.jsonc, or none
                          # non-none → apply overwrites ~/.config/fastfetch/config.jsonc

[aliases]
enabled=false             # source configs/aliases.sh on shell start
```

> **Note:** All `name` / `file` / `config` values are basenames without extension — Termkit appends the right one.

---

## II. What apply does

### shell=bash

Backs up `~/.bashrc` to `~/.bashrc.termkit.bak` (once). Appends a managed block that sources the theme, prints the logo, and sources aliases.

### shell=zsh

Same as bash but for `~/.zshrc`. Also:

- `.zsh-theme` file → copied to `~/.oh-my-zsh/custom/themes/` + `ZSH_THEME=<name>` auto-patched in `~/.zshrc` (replace existing line, else insert before the oh-my-zsh source line).
- `[zsh] plugins` non-empty → `plugins=(...)` auto-patched the same way.
- Standalone `.zsh` themes are sourced from the managed block directly.

### Both

- Re-running `apply` is idempotent — never stacks duplicate blocks.
- `[font] install=true` → copy the `.ttf` to `~/.local/share/fonts/` + `fc-cache -f`.
- `[fastfetch] config` non-none → overwrite `~/.config/fastfetch/config.jsonc`. On uninstall, removed only if unchanged since apply (byte-for-byte match with a shipped file); hand-edits are preserved.
- Anything else in your shell rc is untouched.

---

## III. Managed block markers

Termkit only writes between these two lines. Everything else is yours:

```
# >>> termkit start >>>
# ...
# <<< termkit end <<<
```
