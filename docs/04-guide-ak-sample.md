<h1 align="center">AK preset — sample walkthrough</h1>

The kit ships with a working preset called **ak**: a two-line agnoster-style zsh prompt, an ASCII logo rendered via fastfetch, and a set of shell aliases. This document walks through how to apply it end-to-end, then breaks the theme file open piece by piece so you can build your own on top of it.

Read [01-guide-setup.md](01-guide-setup.md) first — everything below assumes you have zsh + oh-my-zsh + fastfetch installed.

---

## Table of Contents

- [I. Preset overview](#i-preset-overview)
- [II. Apply the preset](#ii-apply-the-preset)
  - [1. Configure settings.conf](#1-configure-settingsconf)
  - [2. Run apply](#2-run-apply)
  - [3. Set ZSH_THEME in ~/.zshrc](#3-set-zsh_theme-in-zshrc)
  - [4. Reload zsh](#4-reload-zsh)
- [III. Anatomy of ak.zsh-theme](#iii-anatomy-of-akzsh-theme) *(next part)*
- [IV. Extras — logo, aliases, fastfetch](#iv-extras--logo-aliases-fastfetch) *(next part)*
- [V. Fork ak into your own theme](#v-fork-ak-into-your-own-theme) *(next part)*

---

## I. Preset overview

The **ak** preset is what a full termkit apply looks like when every option is turned on. It combines four pieces shipped in `configs/`:

| Piece | Where it lives | What it does |
|---|---|---|
| **Theme** | `configs/themes/zsh/ak.zsh-theme` | An oh-my-zsh theme (a copy of `pixegami-agnoster`) that renders a two-line segmented prompt with git branch, dirty state, and status icons. |
| **Logo** | `configs/logo/ak.txt` (or `ak-small.txt`) | An ASCII banner printed at the top of every new shell. |
| **Fastfetch integration** | Set via `[logo] use_fastfetch=true` | Instead of `cat`, `fastfetch --logo` renders the logo alongside OS info (distro, kernel, uptime, packages, ...). |
| **Aliases** | `configs/aliases.sh` | Shell shortcuts: `ll`, `la`, `..`, `...`, `gs`. |

End result: open a new terminal → fastfetch splash with the AK logo → the ak prompt with git awareness ready to go.

---

## II. Apply the preset

### 1. Configure settings.conf

Open `configs/settings.conf` in your editor and set:

```
[shell]
name=zsh

[theme]
name=ak

[font]
name=none
install=false

[logo]
enabled=true
file=ak
use_fastfetch=true

[aliases]
enabled=true
```

> **Note:** Values are basenames without extension. `theme.name=ak` matches `configs/themes/zsh/ak.zsh-theme`, `logo.file=ak` matches `configs/logo/ak.txt`. Use `ak-small` instead of `ak` if you want the smaller logo variant.

### 2. Run apply

```
./install.sh apply
```

Termkit copies `ak.zsh-theme` into `~/.oh-my-zsh/custom/themes/` and appends a managed block to `~/.zshrc` that runs fastfetch and sources aliases. It also prints a reminder about the next step:

```
NOTE: edit ~/.zshrc and set ZSH_THEME="ak" BEFORE the oh-my-zsh source line.
```

### 3. Set ZSH_THEME in ~/.zshrc

Open `~/.zshrc`, find the line starting with `ZSH_THEME=` (usually near the top), and set it to `ak`:

```
ZSH_THEME="ak"
```

This must be set BEFORE the line that reads `source $ZSH/oh-my-zsh.sh`. Termkit's managed block sits at the END of the file, so it cannot set `ZSH_THEME` for you.

### 4. Reload zsh

In the current terminal:

```
exec zsh
```

Or just open a new terminal. You should see the AK logo through fastfetch, followed by the two-line ak prompt with git branch when you are inside a repo.
