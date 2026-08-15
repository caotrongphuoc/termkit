# Setup

Install what your chosen shell needs BEFORE cloning termkit. Skip sections that do not apply.

## Base tools (always required)

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

Termkit uses GNU `sed -i`, so Linux only — not macOS or BSD.

## Bash path

If `[shell] name=bash`, nothing extra is needed. The base tools above are enough.

## Zsh path

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

## Optional extras

### fastfetch

Only when `[logo] use_fastfetch=true`. Prints the logo alongside OS info instead of plain `cat`.

```
sudo apt install fastfetch
```

### fontconfig

Only when `[font] install=true`. Provides `fc-cache` to refresh the font cache after termkit copies fonts into `~/.local/share/fonts/`.

```
sudo apt install fontconfig
```
