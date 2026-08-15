# termkit

Terminal setup kit for Linux. Ship a config, run one command. Bash and zsh.

## Setup

Install what your chosen shell needs BEFORE cloning termkit. Skip sections that do not apply.

### Base tools (always required)

Most Linux distros ship these. On a minimal system:

```
sudo apt install bash coreutils gawk sed git   # Debian/Ubuntu
sudo dnf install bash coreutils gawk sed git   # Fedora
sudo pacman -S bash coreutils gawk sed git     # Arch
```

Termkit uses GNU `sed -i`, so Linux only (not macOS).

### If `[shell] name=bash`

Nothing extra to install. Bash and the base tools above are enough.

### If `[shell] name=zsh`

Full setup for the ak zsh theme (which uses oh-my-zsh + a few plugins):

```
# 1) zsh
sudo apt install zsh

# 2) oh-my-zsh (unattended — will not change your login shell yet)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# 3) plugins used by the shipped setup
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# 4) enable plugins — edit ~/.zshrc, find the `plugins=(...)` line, replace with:
#    plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

# 5) (optional) make zsh your default login shell; log out/in to take effect
chsh -s "$(which zsh)"
```

If you are writing your own zsh theme instead of `.zsh-theme`, oh-my-zsh is not required — see [Adding your own theme](#adding-your-own-theme-font-or-logo).

### Optional extras

- **fastfetch** — only when `[logo] use_fastfetch=true` (prints the logo with OS info instead of plain `cat`).
  ```
  sudo apt install fastfetch
  ```
- **fontconfig** — only when `[font] install=true` (provides `fc-cache`).
  ```
  sudo apt install fontconfig
  ```

## Quickstart

Once Setup above is done:

1. Clone the repo somewhere you plan to keep it (paths written to your shell rc are absolute):
   ```
   git clone https://github.com/caotrongphuoc/termkit.git ~/termkit
   cd ~/termkit
   ```
2. Open `configs/settings.conf` and change what you want. Start with `[shell] name=bash` or `zsh`.
3. Run `./install.sh apply`.
4. For zsh with a `.zsh-theme`: apply prints a reminder — edit `~/.zshrc` and set `ZSH_THEME="<name>"` BEFORE the `source $ZSH/oh-my-zsh.sh` line.
5. Open a new terminal, or `source ~/.bashrc` / `source ~/.zshrc` in the current one.

To undo: `./install.sh uninstall`.

## Commands

```
./install.sh apply       read settings.conf and apply to your shell rc
./install.sh status      show current settings.conf values
./install.sh clean       reset settings.conf to defaults (old file kept as .bak)
./install.sh uninstall   remove termkit changes from both bash AND zsh
./install.sh             print usage
```

## Layout

```
termkit/
├── install.sh
└── configs/
    ├── settings.conf                     # state file: your picks live here
    ├── themes/
    │   ├── bash/*.bash                   # bash themes: set PS1, LS_COLORS, ...
    │   └── zsh/
    │       ├── *.zsh                     # standalone zsh themes (no oh-my-zsh)
    │       └── *.zsh-theme               # oh-my-zsh themes
    ├── fonts/*.ttf                       # copied to ~/.local/share/fonts when install=true
    ├── logo/*.txt                        # printed on shell start when enabled
    └── aliases.sh                        # sourced when aliases are enabled (works in bash and zsh)
```

## settings.conf schema

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

Values for `theme.name`, `font.name`, and `logo.file` are **basenames without extension** — termkit appends the right extension based on shell / file type.

## What apply does

For `shell=bash`:
- Backs up `~/.bashrc` to `~/.bashrc.termkit.bak` on the first run.
- Appends a managed block that sources the theme, prints the logo, and sources aliases.

For `shell=zsh`:
- Same, but writes to `~/.zshrc` and `~/.zshrc.termkit.bak`.
- If the theme is a `.zsh-theme` file, copies it to `~/.oh-my-zsh/custom/themes/<name>.zsh-theme` and reminds you to set `ZSH_THEME=<name>` yourself. Standalone `.zsh` themes are sourced from the managed block directly.

Common to both:
- Re-running `apply` strips the old managed block and writes a new one — never stacks duplicates.
- If `[font] install=true`, the `.ttf` is copied to `~/.local/share/fonts/` and `fc-cache -f` runs.
- Anything else in your shell rc is left alone.

Managed block markers:

```
# >>> termkit start >>>
# ...
# <<< termkit end <<<
```

## Adding your own theme, font, or logo

- **Bash theme**: drop `mytheme.bash` into `configs/themes/bash/`. Inside, set `PS1`, `LS_COLORS`, or anything else. Set `[shell] name=bash` and `[theme] name=mytheme`.
- **Zsh standalone theme**: drop `mytheme.zsh` into `configs/themes/zsh/`. Inside, set `PROMPT`, `autoload -Uz vcs_info`, etc. Only requires zsh.
- **Zsh oh-my-zsh theme**: drop `mytheme.zsh-theme` into `configs/themes/zsh/`. Requires oh-my-zsh at `~/.oh-my-zsh/`.
- **Font**: drop `MyFont.ttf` into `configs/fonts/`. Set `[font] name=MyFont`, `install=true`.
- **Logo**: drop `mylogo.txt` into `configs/logo/`. Set `[logo] file=mylogo`, `enabled=true`. Optionally `use_fastfetch=true`.

## Uninstall

`./install.sh uninstall`:

- Removes the managed block from BOTH `~/.bashrc` and `~/.zshrc` (whichever has it).
- Removes any file under `~/.local/share/fonts/` whose basename matches one in `configs/fonts/`. Fonts from other sources are untouched.
- Removes any file under `~/.oh-my-zsh/custom/themes/` whose basename matches one in `configs/themes/zsh/*.zsh-theme`. Themes from other sources are untouched.

Backups at `~/.bashrc.termkit.bak` and `~/.zshrc.termkit.bak` are kept. To fully revert:

```
cp ~/.bashrc.termkit.bak ~/.bashrc
cp ~/.zshrc.termkit.bak  ~/.zshrc
```
