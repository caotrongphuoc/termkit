<h1 align="center">Extending Termkit</h1>

Add your own theme, font, or logo. Drop a file in the right folder and point `settings.conf` at it.

---

## Table of Contents

- [I. Themes](#i-themes)
- [II. Font](#ii-font)
- [III. Logo](#iii-logo)
- [IV. Fastfetch config](#iv-fastfetch-config)

---

## I. Themes

### Bash theme

Drop `mytheme.bash` into `configs/themes/bash/`. Set `PS1`, `LS_COLORS`, or anything each new shell should run.

```
[shell] name=bash
[theme] name=mytheme
```

### Zsh standalone theme

Drop `mytheme.zsh` into `configs/themes/zsh/`. Set `PROMPT`, `autoload -Uz vcs_info`, etc. No oh-my-zsh needed.

```
[shell] name=zsh
[theme] name=mytheme
```

### Zsh oh-my-zsh theme

Drop `mytheme.zsh-theme` into `configs/themes/zsh/`. Requires `~/.oh-my-zsh/`.

On apply, Termkit copies the file to `~/.oh-my-zsh/custom/themes/` and auto-patches `ZSH_THEME="mytheme"` in `~/.zshrc`.

---

## II. Font

Drop `MyFont.ttf` into `configs/fonts/`.

```
[font]
name=MyFont
install=true
```

On apply, copied to `~/.local/share/fonts/` + `fc-cache -f`.

---

## III. Logo

Drop `mylogo.txt` into `configs/logo/`.

```
[logo]
enabled=true
file=mylogo
use_fastfetch=false       # or true to render with fastfetch
```

---

## IV. Fastfetch config

Drop `myconfig.jsonc` into `configs/fastfetch/`. See the [fastfetch wiki](https://github.com/fastfetch-cli/fastfetch/wiki/Configuration) for format.

```
[fastfetch]
config=myconfig
```

On apply, overwrites `~/.config/fastfetch/config.jsonc`. On uninstall, removed only if unchanged since apply (byte-for-byte); hand-edits preserved.
