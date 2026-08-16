<h1 align="center">AK preset — sample walkthrough</h1>

Applies the shipped **ak** preset end-to-end, then shows how to fork it into your own theme. Read [00-guide-setup.md](00-guide-setup.md) first — assumes zsh + oh-my-zsh + fastfetch already installed.

---

## Table of Contents

- [I. Preset overview](#i-preset-overview)
- [II. Apply the preset](#ii-apply-the-preset)
- [III. Anatomy of ak.zsh-theme](#iii-anatomy-of-akzsh-theme)
- [IV. Extras](#iv-extras)
- [V. Fork into your own theme](#v-fork-into-your-own-theme)

---

## I. Preset overview

Every option turned on. Five pieces:

| Piece | Where |
|---|---|
| **Theme** | `configs/themes/zsh/ak.zsh-theme` (fork of pixegami-agnoster) |
| **Nerd Font** | `configs/fonts/JetBrainsMonoNerdFont-Regular.ttf` |
| **Logo** | `configs/logo/ak.txt` (or `ak-small.txt`) |
| **Fastfetch config** | `configs/fastfetch/ak.jsonc` |
| **Aliases** | `configs/aliases.sh` |

End result: new terminal → fastfetch splash with AK logo → two-line ak prompt with git awareness.

---

## II. Apply the preset

### 1. Configure `settings.conf`

```
[shell]
name=zsh

[zsh]
plugins=git zsh-syntax-highlighting zsh-autosuggestions

[theme]
name=ak

[font]
name=JetBrainsMonoNerdFont-Regular
install=true

[logo]
enabled=true
file=ak
use_fastfetch=true

[fastfetch]
config=ak

[aliases]
enabled=true
```

> **Note:** Values are basenames — Termkit appends the right extension. Use `ak-small` in `logo.file` for the compact variant. After apply, set your terminal emulator font — see [00-guide-setup.md Section VI.2](00-guide-setup.md#2-set-your-terminal-to-use-it).

### 2. Run apply

```
./install.sh apply
```

Does four things:

- Copies `ak.zsh-theme` into `~/.oh-my-zsh/custom/themes/`.
- Auto-patches `ZSH_THEME="ak"` in `~/.zshrc`.
- Auto-patches `plugins=(...)` in `~/.zshrc`.
- Appends a managed block that runs fastfetch and sources aliases.

### 3. Reload zsh

```
exec zsh
```

Or open a new terminal.

---

## III. Anatomy of ak.zsh-theme

`ak.zsh-theme` (~200 lines) is a fork of `pixegami-agnoster`. Every customization point has a `# TWEAK:` marker inline — jump to them with:

```
grep -n TWEAK configs/themes/zsh/ak.zsh-theme
```

**Structure**: the prompt builds from **segments** — colored blocks separated by a Powerline arrow. Each segment picks bg/fg colors and prints content; a helper draws the arrow into the next segment's color.

**Functions (in order rendered by `build_prompt`):**

| Function | What it does | Common tweaks |
|---|---|---|
| `prompt_head` | Top line: `[~/path]` in light grey, path truncated past 64 chars | format, truncation limit, add timestamp |
| `prompt_status` | Status icons: ✘ (last cmd failed), ⚡ (root), ⚙ (bg jobs) | swap emojis, remove conditions |
| `prompt_virtualenv` | Python venv (Anaconda-only) | swap body for plain `$VIRTUAL_ENV` |
| `prompt_context` | `user` in green/dark-grey, yellow if root | colors, add `@host` |
| `prompt_git` | Branch + dirty/clean colors + mode marker (bisect/merge/rebase) | colors, branch icon, ahead/behind |
| `prompt_bzr` / `prompt_hg` | Bazaar / Mercurial (comment out if git-only) | — |
| `prompt_end` | Closes final segment | plumbing |

**Helpers** (leave alone): `prompt_segment` chains colored blocks; `SEGMENT_SEPARATOR=$''` is the Powerline arrow — swap for `>` / `|` / `❯` if you don't have a Nerd font (has a `# TWEAK:` marker for this).

**PROMPT line** at the bottom just resets styles and calls `build_prompt` per render — rarely edit.

`RETVAL=$?` at the top of `build_prompt` captures the last exit code — **don't move it** or `prompt_status` always reports success.

---

## IV. Extras

### Logo file

`configs/logo/*.txt` are plain text — box-drawing chars, ASCII art, unicode. `ak.txt` is full, `ak-small.txt` compact. Generate your own with [`jp2a`](https://github.com/Talinx/jp2a) or [`ascii-image-converter`](https://github.com/TheZoraiz/ascii-image-converter). Keep width reasonable — fastfetch prints info on the right.

### Aliases

`configs/aliases.sh` is sourced by both bash and zsh when `[aliases] enabled=true`. Append lines like:

```
alias k='kubectl'
alias dc='docker compose'
```

New terminals pick up changes immediately — no re-apply needed.

### Fastfetch toggle

`[logo] use_fastfetch=false` → `cat "<logo>"` (raw art). `true` → `fastfetch --logo "<logo>"` (art + OS info). If `true` but fastfetch missing, falls back to `cat` with a warning.

### Fastfetch config file

`[fastfetch] config=ak` overwrites `~/.config/fastfetch/config.jsonc` with `configs/fastfetch/ak.jsonc` on apply. Uninstall removes it only if unchanged since apply.

Two ways to customize the info lines:

- **In the repo**: edit `configs/fastfetch/ak.jsonc`, re-run apply. Uninstall still cleans up.
- **On your machine only**: set `[fastfetch] config=none`, edit `~/.config/fastfetch/config.jsonc` directly. Termkit won't touch it.

Format: [fastfetch wiki](https://github.com/fastfetch-cli/fastfetch/wiki/Configuration).

---

## V. Fork into your own theme

```
cp configs/themes/zsh/ak.zsh-theme configs/themes/zsh/mytheme.zsh-theme
```

Edit `mytheme.zsh-theme` — jump between edit points via `grep -n TWEAK mytheme.zsh-theme`. Common starters: swap colors in `prompt_context` / `prompt_git`, comment out `prompt_bzr` / `prompt_hg`.

Point termkit at it:

```
[theme]
name=mytheme
```

Then:

```
./install.sh apply
exec zsh
```

Termkit auto-patches `ZSH_THEME="mytheme"` for you. Further edits: re-apply to sync into `~/.oh-my-zsh/custom/themes/`, then reload zsh.

Same pattern for bash: `cp configs/themes/bash/ak.bash configs/themes/bash/mytheme.bash`, edit, set `[shell] name=bash` and `[theme] name=mytheme`, apply, new terminal.
