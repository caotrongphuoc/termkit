<h1 align="center">Setup guide</h1>

Install the tools Termkit needs on your machine BEFORE cloning the repo. This document lists exactly what to install for each supported shell, plus optional extras.

---

## Table of Contents

- [I. Base tools (always required)](#i-base-tools-always-required)
- [II. Bash path](#ii-bash-path)
- [III. Zsh path](#iii-zsh-path)
  - [1. Install zsh](#1-install-zsh)
  - [2. Install oh-my-zsh](#2-install-oh-my-zsh)
  - [3. Install zsh plugins (per-theme optional)](#3-install-zsh-plugins-per-theme-optional)
  - [4. Make zsh your default shell (optional)](#4-make-zsh-your-default-shell-optional)
- [IV. Optional extras](#iv-optional-extras)
  - [1. fastfetch](#1-fastfetch)
  - [2. fontconfig](#2-fontconfig)

---

## I. Base tools (always required)

Most Linux distros ship these. On a minimal system:

Debian / Ubuntu:

```
sudo apt install bash coreutils gawk sed git
```

Fedora:

```
sudo dnf install bash coreutils gawk sed git
```

Arch:

```
sudo pacman -S bash coreutils gawk sed git
```

> **Note:** Termkit uses GNU `sed -i`. Linux only — not macOS or BSD.

---

## II. Bash path

If `[shell] name=bash`, nothing extra is needed. The base tools above are enough.

---

## III. Zsh path

Setup for `[shell] name=zsh` has four sub-steps. Only steps 1 and 2 are always required; step 3 depends on the theme you pick, step 4 is convenience.

### 1. Install zsh

```
sudo apt install zsh
```

### 2. Install oh-my-zsh

Only required if your `[theme] name` points to a `.zsh-theme` file. Standalone `.zsh` themes do not need oh-my-zsh.

The unattended install below will NOT change your login shell yet:

```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

### 3. Install zsh plugins (per-theme optional)

Themes that use syntax highlighting or autosuggestions expect these plugins. Skip if your theme does not use them.

```
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

Then edit `~/.zshrc`. Find the line starting with `plugins=(` and add the plugin names:

```
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
```

### 4. Make zsh your default shell (optional)

Log out and back in after running:

```
chsh -s "$(which zsh)"
```

> **Note:** Until you do this, new terminals still open in bash. To try zsh in the current terminal without changing your login shell, just type `zsh`. Do not run `source ~/.zshrc` from bash — oh-my-zsh refuses to load under bash and will print an error.

---

## IV. Optional extras

### 1. fastfetch

Only when `[logo] use_fastfetch=true`. Prints the logo alongside OS info instead of plain `cat`.

fastfetch is not in the default apt repos of older Ubuntu (22.04 and earlier). Pick one of the install methods below.

**a. Download the .deb from GitHub releases** — works on any Ubuntu version:

```
curl -LO https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb
sudo dpkg -i fastfetch-linux-amd64.deb
sudo apt install -f     # fix missing deps if any
```

**b. PPA** — auto-updates through apt afterwards:

```
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update
sudo apt install fastfetch
```

**c. Snap:**

```
sudo snap install fastfetch
```

**d. Direct apt** — only on Ubuntu 24.04+ and current Fedora / Arch:

```
sudo apt install fastfetch          # Debian 13+, Ubuntu 24.04+
sudo dnf install fastfetch          # Fedora
sudo pacman -S fastfetch            # Arch
```

Verify with `fastfetch --version`.

### 2. fontconfig

Only when `[font] install=true`. Provides `fc-cache` to refresh the font cache after Termkit copies fonts into `~/.local/share/fonts/`.

```
sudo apt install fontconfig
```
