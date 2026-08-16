<h1 align="center">Setup guide</h1>

Install these BEFORE cloning termkit.

---

## Table of Contents

- [I. Base tools](#i-base-tools)
- [II. Bash path](#ii-bash-path)
- [III. Zsh path](#iii-zsh-path)
- [IV. Optional: fastfetch](#iv-optional-fastfetch)
- [V. Optional: fontconfig](#v-optional-fontconfig)
- [VI. Nerd Font](#vi-nerd-font)

---

## I. Base tools

Usually pre-installed. On a minimal system:

```
sudo apt install bash coreutils gawk sed git   # Debian/Ubuntu
sudo dnf install bash coreutils gawk sed git   # Fedora
sudo pacman -S bash coreutils gawk sed git     # Arch
```

> **Note:** Termkit uses GNU `sed -i`. Linux only.

---

## II. Bash path

Nothing extra. Base tools are enough.

---

## III. Zsh path

Steps 1-2 are required; 3 depends on theme; 4 is convenience.

### 1. Install zsh

```
sudo apt install zsh
```

### 2. Install oh-my-zsh

Required for `.zsh-theme` files (not for standalone `.zsh`). Unattended install does NOT change your login shell:

```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

### 3. Install zsh plugins (optional)

Needed by themes that use syntax highlighting or autosuggestions:

```
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

Enable via `[zsh] plugins=git zsh-syntax-highlighting zsh-autosuggestions` in `settings.conf` — apply patches `~/.zshrc` for you. Or leave empty and edit `~/.zshrc` yourself.

> **Note:** `./install.sh apply` auto-fixes the `[oh-my-zsh] Insecure completion-dependent directories detected` warning. If it appears after you install plugins manually, re-run apply, or fix in zsh: `compaudit | xargs chmod g-w,o-w`.

### 4. Make zsh your default shell (optional)

```
chsh -s "$(which zsh)"
```

Log out and back in. Meanwhile, type `zsh` in the current terminal to try it — don't `source ~/.zshrc` from bash, oh-my-zsh refuses to load.

---

## IV. Optional: fastfetch

Needed when `[logo] use_fastfetch=true`. Not in default apt on Ubuntu 22.04 and earlier — pick one:

**a. .deb from GitHub** (any Ubuntu):
```
curl -LO https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb
sudo dpkg -i fastfetch-linux-amd64.deb && sudo apt install -f
```

**b. PPA** (auto-updates):
```
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update && sudo apt install fastfetch
```

**c. Snap:** `sudo snap install fastfetch`

**d. Direct** (Ubuntu 24.04+, Fedora, Arch): `apt/dnf/pacman install fastfetch`

Verify: `fastfetch --version`.

---

## V. Optional: fontconfig

Needed when `[font] install=true`. Provides `fc-cache`:

```
sudo apt install fontconfig
```

---

## VI. Nerd Font

The kit ships `configs/fonts/JetBrainsMonoNerdFont-Regular.ttf` — needed for Powerline arrow glyphs (``). Without it, arrows render as tofu boxes.

### 1. Install the font

```
[font]
name=JetBrainsMonoNerdFont-Regular
install=true
```

Run `./install.sh apply` → copied to `~/.local/share/fonts/`, cache refreshed (needs [fontconfig](#v-optional-fontconfig)).

### 2. Set your terminal to use it

- **GNOME Terminal**: Preferences → Profile → Text → Custom font → **JetBrainsMonoNerdFont Regular**
- **Kitty** (`~/.config/kitty/kitty.conf`): `font_family JetBrainsMonoNerdFont-Regular`
- **Alacritty** (`~/.config/alacritty/alacritty.toml`): `[font.normal]` + `family = "JetBrainsMonoNerdFont-Regular"`

> **Note:** Some terminals auto-fallback via fontconfig — installing the font alone may be enough.
