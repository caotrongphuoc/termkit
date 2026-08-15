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
- [III. Anatomy of ak.zsh-theme](#iii-anatomy-of-akzsh-theme)
  - [1. Powerline segment separator](#1-powerline-segment-separator)
  - [2. Segment helpers — prompt_segment and prompt_end](#2-segment-helpers--prompt_segment-and-prompt_end)
  - [3. Content segments](#3-content-segments)
  - [4. Composition — build_prompt](#4-composition--build_prompt)
  - [5. The PROMPT line](#5-the-prompt-line)
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
