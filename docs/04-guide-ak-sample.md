<h1 align="center">AK preset — sample walkthrough</h1>

The kit ships with a working preset called **ak**: a two-line agnoster-style zsh prompt, an ASCII logo rendered via fastfetch, and a set of shell aliases. This document walks through how to apply it end-to-end, then breaks the theme file open piece by piece so you can build your own on top of it.

Read [01-guide-setup.md](01-guide-setup.md) first — everything below assumes you have zsh + oh-my-zsh + fastfetch installed.

---

## Table of Contents

- [I. Preset overview](#i-preset-overview)
- [II. Apply the preset](#ii-apply-the-preset)
  - [1. Configure settings.conf](#1-configure-settingsconf)
  - [2. Run apply](#2-run-apply)
  - [3. Reload zsh](#3-reload-zsh)
- [III. Anatomy of ak.zsh-theme](#iii-anatomy-of-akzsh-theme)
  - [1. Powerline segment separator](#1-powerline-segment-separator)
  - [2. Segment helpers — prompt_segment and prompt_end](#2-segment-helpers--prompt_segment-and-prompt_end)
  - [3. Content segments](#3-content-segments)
  - [4. Composition — build_prompt](#4-composition--build_prompt)
  - [5. The PROMPT line](#5-the-prompt-line)
- [IV. Extras — logo, aliases, fastfetch](#iv-extras--logo-aliases-fastfetch)
  - [1. Logo file](#1-logo-file)
  - [2. Aliases](#2-aliases)
  - [3. Fastfetch toggle](#3-fastfetch-toggle)
  - [4. Fastfetch config file](#4-fastfetch-config-file)
- [V. Fork ak into your own theme](#v-fork-ak-into-your-own-theme)

---

## I. Preset overview

The **ak** preset is what a full termkit apply looks like when every option is turned on. It combines four pieces shipped in `configs/`:

| Piece | Where it lives | What it does |
|---|---|---|
| **Theme** | `configs/themes/zsh/ak.zsh-theme` | An oh-my-zsh theme (a copy of `pixegami-agnoster`) that renders a two-line segmented prompt with git branch, dirty state, and status icons. |
| **Nerd Font** | `configs/fonts/JetBrainsMonoNerdFont-Regular.ttf` | Installed into `~/.local/share/fonts/` so the terminal can render Powerline arrows. |
| **Logo** | `configs/logo/ak.txt` (or `ak-small.txt`) | An ASCII banner printed at the top of every new shell. |
| **Fastfetch integration** | `[logo] use_fastfetch=true` + `[fastfetch] config=ak` | `fastfetch --logo` renders the logo alongside OS info, with the info list from `configs/fastfetch/ak.jsonc`. |
| **Aliases** | `configs/aliases.sh` | Shell shortcuts: `ll`, `la`, `..`, `...`, `gs`. |

End result: open a new terminal → fastfetch splash with the AK logo → the ak prompt with git awareness ready to go.

---

## II. Apply the preset

### 1. Configure settings.conf

Open `configs/settings.conf` in your editor and set:

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

> **Note:** Values are basenames without extension. `theme.name=ak` matches `configs/themes/zsh/ak.zsh-theme`, `logo.file=ak` matches `configs/logo/ak.txt`, `fastfetch.config=ak` matches `configs/fastfetch/ak.jsonc`. Use `ak-small` instead of `ak` in `logo.file` if you want the smaller logo variant.
>
> After apply, remember to point your terminal emulator at the newly installed font — see [01-guide-setup.md Section V.2](01-guide-setup.md#2-set-your-terminal-emulator-to-use-it).

### 2. Run apply

```
./install.sh apply
```

Termkit does four things:

- Copies `ak.zsh-theme` into `~/.oh-my-zsh/custom/themes/`.
- Auto-patches `ZSH_THEME="ak"` in `~/.zshrc` (replaces the existing line, or inserts one before the `source $ZSH/oh-my-zsh.sh` line).
- Auto-patches `plugins=(git zsh-syntax-highlighting zsh-autosuggestions)` in `~/.zshrc` the same way.
- Appends a managed block at the end of `~/.zshrc` that runs fastfetch and sources aliases.

You should see output like:

```
Installed oh-my-zsh theme: ~/.oh-my-zsh/custom/themes/ak.zsh-theme
Updated ZSH_THEME to "ak" in ~/.zshrc
Applied. Open a new terminal to see changes.
```

### 3. Reload zsh

In the current terminal:

```
exec zsh
```

Or just open a new terminal. You should see the AK logo through fastfetch, followed by the two-line ak prompt with git branch when you are inside a repo.

---

## III. Anatomy of ak.zsh-theme

`configs/themes/zsh/ak.zsh-theme` is a copy of `pixegami-agnoster`, which itself extends oh-my-zsh's classic `agnoster` theme. About 200 lines total. This section walks through the pieces you are most likely to tweak.

The theme builds the prompt from **segments**: colored blocks separated by a powerline arrow. Each segment picks its own background and foreground and prints its own content; a helper draws the transition arrow into the next segment's color.

### 1. Powerline segment separator

```zsh
() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  SEGMENT_SEPARATOR=$'\ue0b0'
}
```

`$'\ue0b0'` is the unicode escape for the powerline "solid right arrow" — the character that draws the smooth transition between colored blocks. Rendering it correctly requires a **powerline-patched font** (Meslo LG, JetBrainsMono Nerd Font, ...).

**To customize:**
- No powerline font? Swap for a plain character: `SEGMENT_SEPARATOR='>'` or `SEGMENT_SEPARATOR='|'` or `SEGMENT_SEPARATOR='❯'`.
- Keep the anonymous-function wrapper — it forces UTF-8 locale so the escape resolves to a real byte sequence.

### 2. Segment helpers — `prompt_segment` and `prompt_end`

```zsh
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  ...
}
```

`prompt_segment <bg> <fg> [content]` draws one colored block:

- `%K{n}` sets the background color, `%F{n}` sets the foreground (any 0..255 palette index).
- If the previous segment used a different background, it draws the separator arrow first in the previous background's color.
- The content argument is optional — you can open a segment and then fill it with additional `echo -n` calls before the next segment starts.

`prompt_end` closes the last segment by drawing one final arrow into "no background".

These are plumbing. Leave them alone and edit the content functions below.

### 3. Content segments

The prompt is composed of a few small functions, each drawing one segment. `build_prompt` picks which ones render and in what order.

#### a. `prompt_context` — user @ host

```zsh
prompt_segment 008 010 "%(!.%{%F{yellow}%}.)%n"
```

- Background `008` (dark grey), foreground `010` (bright green).
- `%n` is the username. `%(!.<if root>.)` switches to yellow when running as root.

**To customize:**
- Change colors: swap `008`/`010` for any 0..255 palette index. Preview with `for i in {0..255}; do print -P "%F{$i}$i%f"; done`.
- Show the host too: replace `%n` with `%n@%m`.
- Hide the segment for your usual login: guard with `[[ "$USER" != "youruser" ]] && prompt_segment ...`.

#### b. `prompt_git` — branch and dirty state

The most useful segment. Skips silently outside a git repo (`git rev-parse --is-inside-work-tree`).

- Branch name (or short SHA if you are on a detached HEAD).
- Yellow background when the working tree is dirty; cyan-on-green when clean.
- Mode suffix: `>M<` (merging), `>R>` (rebasing), `<B>` (bisecting).
- Stage/unstage counters via `vcs_info` (`+` staged, `-` unstaged).

**To customize:**
- Colors: `prompt_segment yellow black` (dirty) and `prompt_segment 014 002` (clean).
- Change the branch icon: edit `PL_BRANCH_CHAR=$'\ue0a0'` — needs a powerline font.
- Add ahead/behind counts: `git rev-list --count @{u}..HEAD` and `git rev-list --count HEAD..@{u}`.

#### c. `prompt_status` — status icons

```zsh
[[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
[[ $UID -eq 0 ]]    && symbols+="%{%F{yellow}%}⚡"
[[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"
```

Compact icons that appear before context:

- `✘` — last command exited non-zero.
- `⚡` — running as root.
- `⚙` — one or more background jobs are running.

**To customize:** swap the emoji for whatever you like, or drop conditions you do not care about (e.g. remove the root check on a personal machine).

#### d. `prompt_virtualenv` — python virtualenv

Only fires when `$CONDA_PROMPT_MODIFIER` is set (Anaconda-specific). If you use plain `venv`/`virtualenv` instead, replace the body with:

```zsh
prompt_virtualenv() {
  [[ -n $VIRTUAL_ENV ]] && prompt_segment black default "${VIRTUAL_ENV:t}"
}
```

`${VIRTUAL_ENV:t}` is zsh's `:t` modifier — it prints just the basename.

#### e. `prompt_head` — top line with directory

```zsh
prompt_head() {
  echo "\r               "
  echo "\r %{%F{7}%}[%64<..<%~%<<]"
}
```

Draws line 1 of the two-line prompt: a `[~/path]` block in light grey.

- `%~` — current directory with `~` for `$HOME`.
- `%64<..<%~%<<` — zsh path truncation: if `%~` is longer than 64 chars, prepend `..` and keep only the tail. Handy for deep monorepo paths.

**To customize:**
- Add a timestamp: `[%D{%H:%M} | %64<..<%~%<<]`.
- Change the truncation limit: `%40<..<...%<<`.
- Drop the leading blank line if you want a compact prompt.

### 4. Composition — `build_prompt`

```zsh
build_prompt() {
  RETVAL=$?
  prompt_head
  prompt_status
  prompt_virtualenv
  prompt_context
  # prompt_dir
  prompt_git
  prompt_bzr
  prompt_hg
  prompt_end
}
```

This is where you pick which segments render and in what order.

**To customize:**
- Comment out `prompt_bzr` and `prompt_hg` if you only use git — they run a `command -v` check every prompt.
- Reorder segments: each one paints against the previous segment's background, so swapping order changes which arrow-transition color you see.
- Add your own: write a `prompt_foo()` and drop `prompt_foo` in the chain wherever you want it to appear.

`RETVAL=$?` on the first line captures the exit code of your last command BEFORE anything else runs — do not move it, or `prompt_status` will always report success.

### 5. The `PROMPT` line

```zsh
PROMPT='%{%f%b%k%}$(build_prompt) '
```

- `%{%f%b%k%}` resets foreground / bold / background before each render — otherwise leftover styles from your commands would bleed into the prompt.
- `$(build_prompt)` calls the composition on every render (`setopt PROMPT_SUBST` is what oh-my-zsh enables so `$(...)` re-evaluates each time).
- The trailing space is where the cursor sits after the prompt is drawn.

Rarely a reason to edit this line — customize inside `build_prompt` instead.

---

## IV. Extras — logo, aliases, fastfetch

### 1. Logo file

`configs/logo/ak.txt` and `configs/logo/ak-small.txt` are plain text — no code, no escape sequences (unless you add ANSI colors yourself). Box-drawing characters, ASCII art, unicode — anything that displays in a terminal works.

`ak.txt` is the full-size banner (~30 lines). `ak-small.txt` is a compact version for narrow terminals. Pick which one with `[logo] file=ak` or `[logo] file=ak-small` in `settings.conf`.

**To customize:**
- Edit the file directly with any text editor.
- Generate ASCII art from an image with tools like [`jp2a`](https://github.com/Talinx/jp2a) or [`ascii-image-converter`](https://github.com/TheZoraiz/ascii-image-converter).
- Keep the width in check — fastfetch prints info on the right, so a very wide logo pushes the info off-screen.

### 2. Aliases

`configs/aliases.sh` is sourced by both bash and zsh when `[aliases] enabled=true`. The syntax `alias name='command'` is identical in both shells.

The default set: `ll`, `la`, `..`, `...`, `gs`. Add more by appending lines:

```
alias k='kubectl'
alias dc='docker compose'
alias serve='python3 -m http.server'
```

Aliases are sourced from the same path every shell start, so a new terminal picks up changes without re-running `./install.sh apply`. Apply is only needed to toggle `enabled` on or off.

### 3. Fastfetch toggle

The `[logo] use_fastfetch` field decides how the logo is printed:

| Value | Command in managed block | Output |
|---|---|---|
| `false` (default) | `cat "<logo>"` | Just the ASCII art. |
| `true` | `fastfetch --logo "<logo>"` | The ASCII art on the left, OS / kernel / uptime / packages / etc. on the right. |

If `use_fastfetch=true` but fastfetch is not installed at apply time, termkit prints a warning and falls back to `cat`. Install fastfetch (see [01-guide-setup.md](01-guide-setup.md)) then re-run `./install.sh apply` to flip the block to the fastfetch line.

### 4. Fastfetch config file

The `[fastfetch] config=ak` field points at `configs/fastfetch/ak.jsonc`, which decides what info lines show up next to the logo — OS, host, kernel, uptime, packages, shell, terminal, font, and the second block with CPU, GPU, memory, disk, local IP.

On apply, Termkit overwrites `~/.config/fastfetch/config.jsonc` with the shipped copy. On uninstall, it removes the file only if the content is still byte-for-byte identical to what was shipped — any hand-edit is preserved.

**To customize the info lines** (add battery, remove GPU, change colors, ...), you have two options:

- **Edit in the repo**: edit `configs/fastfetch/ak.jsonc`, then re-run `./install.sh apply` to sync the change to `~/.config/fastfetch/config.jsonc`. Uninstall still cleans up because the content stays identical between repo and system.
- **Edit only on your machine**: set `[fastfetch] config=none` in `settings.conf`, then edit `~/.config/fastfetch/config.jsonc` directly. Termkit will not touch that file when config is `none`.

See the [fastfetch config wiki](https://github.com/fastfetch-cli/fastfetch/wiki/Configuration) for the JSONC schema.

---

## V. Fork ak into your own theme

The ak theme is meant to be forked. Here is the loop for building your own on top of it.

### 1. Copy the file

```
cp configs/themes/zsh/ak.zsh-theme configs/themes/zsh/mytheme.zsh-theme
```

Edit the header attribution to note it is your fork (keep the upstream credits — they are required by the license).

### 2. Tweak content

Open `configs/themes/zsh/mytheme.zsh-theme` and change whatever you want — see [Section III](#iii-anatomy-of-akzsh-theme) for what each function does. Common starter tweaks:

- Swap the segment colors in `prompt_context` and `prompt_git`.
- Comment out `prompt_bzr` and `prompt_hg` in `build_prompt`.
- Add a timestamp segment before `prompt_head`.

### 3. Point termkit at it

```
[theme]
name=mytheme
```

### 4. Apply and reload

```
./install.sh apply
```

Termkit patches `ZSH_THEME="mytheme"` in `~/.zshrc` for you. Reload with `exec zsh` or open a new terminal.

### 5. Iterate

Any further edit to `mytheme.zsh-theme` needs an `./install.sh apply` to re-copy the file into `~/.oh-my-zsh/custom/themes/`, then a new zsh shell (or `omz reload`) to see the change.

---

The same pattern works for a bash theme: `cp configs/themes/bash/ak.bash configs/themes/bash/mytheme.bash`, edit, set `[shell] name=bash` and `[theme] name=mytheme`, apply, open a new terminal.
