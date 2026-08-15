<h1 align="center">Extending Termkit</h1>

Add your own theme, font, or logo to the kit. Everything lives under `configs/`; drop a file in the right folder and point `settings.conf` at it.

---

## Table of Contents

- [I. Themes](#i-themes)
  - [1. Bash theme](#1-bash-theme)
  - [2. Zsh standalone theme](#2-zsh-standalone-theme)
  - [3. Zsh oh-my-zsh theme](#3-zsh-oh-my-zsh-theme)
- [II. Font](#ii-font)
- [III. Logo](#iii-logo)
- [IV. Fastfetch config](#iv-fastfetch-config)

---

## I. Themes

### 1. Bash theme

Drop `mytheme.bash` into `configs/themes/bash/`. Inside, set `PS1`, `LS_COLORS`, or anything else you want each new shell to run.

Then in `settings.conf`:

```
[shell]
name=bash

[theme]
name=mytheme
```

### 2. Zsh standalone theme

Drop `mytheme.zsh` into `configs/themes/zsh/`. Inside, set `PROMPT`, `autoload -Uz vcs_info`, etc. Requires only zsh — no oh-my-zsh.

```
[shell]
name=zsh

[theme]
name=mytheme
```

### 3. Zsh oh-my-zsh theme

Drop `mytheme.zsh-theme` into `configs/themes/zsh/`. Requires oh-my-zsh at `~/.oh-my-zsh/`.

On apply, Termkit copies the file to `~/.oh-my-zsh/custom/themes/`. You then set `ZSH_THEME="mytheme"` manually in `~/.zshrc`, BEFORE the `source $ZSH/oh-my-zsh.sh` line.

---

## II. Font

Drop `MyFont.ttf` into `configs/fonts/`.

```
[font]
name=MyFont
install=true
```

On apply, Termkit copies the file into `~/.local/share/fonts/` and refreshes the cache with `fc-cache -f`.

---

## III. Logo

Drop `mylogo.txt` into `configs/logo/`.

```
[logo]
enabled=true
file=mylogo
use_fastfetch=false       # or true to render with fastfetch instead of cat
```

---

## IV. Fastfetch config

Drop `myconfig.jsonc` into `configs/fastfetch/`. See the [fastfetch config wiki](https://github.com/fastfetch-cli/fastfetch/wiki/Configuration) for the format.

```
[fastfetch]
config=myconfig
```

On apply, Termkit copies the file into `~/.config/fastfetch/config.jsonc` (overwrite, no backup). On uninstall, the file is removed only if its content is still byte-for-byte identical to your shipped file — hand-edits are preserved.
