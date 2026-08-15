<div align="center">

![Repo Traffic](https://komarev.com/ghpvc/?username=termkit&label=Repo+Traffic&color=blue&style=flat-square)

</div>

# Termkit - Terminal Setup Kit for Linux

<hr>

## Documentation

| File | Description |
|---|---|
| [README.md](README.md) | Project overview, layout, commands, and uninstall. |
| [docs/01-guide-setup.md](docs/01-guide-setup.md) | Install prerequisites (bash, zsh, oh-my-zsh, plugins, fastfetch, fontconfig) for each target shell. |
| [docs/02-guide-settings.md](docs/02-guide-settings.md) | `settings.conf` schema and what the `apply` command does to your shell rc. |
| [docs/03-guide-extending.md](docs/03-guide-extending.md) | Add your own theme, font, or logo to the kit. |

## Introduction

termkit is a small toolkit for configuring Linux terminals — pick a theme, prompt, logo, aliases, and font, then apply them with one command. Works for both **bash** and **zsh** setups. While using termkit, you rely on the following building blocks:

- **State file:** A single `configs/settings.conf` captures every choice you have made.
- **Managed block:** Termkit only writes a fenced block into `~/.bashrc` or `~/.zshrc`; the rest of the file is untouched.
- **Reversible:** Every apply is idempotent; a single `uninstall` command wipes the block and any files termkit installed.

### I. How to Use

Once prerequisites are installed (see [docs/01-guide-setup.md](docs/01-guide-setup.md)):

```
git clone https://github.com/caotrongphuoc/termkit.git ~/termkit
cd ~/termkit
$EDITOR configs/settings.conf     # pick shell, theme, logo, aliases
./install.sh apply
```

Then open a new terminal, or `source ~/.bashrc` / `source ~/.zshrc`.

To undo: `./install.sh uninstall`.

### II. Commands

| Command | What it does |
|---|---|
| `./install.sh apply` | Reads settings.conf and applies to your shell rc. |
| `./install.sh status` | Prints current settings.conf values. |
| `./install.sh clean` | Resets settings.conf to defaults (old file kept as `.bak`). |
| `./install.sh uninstall` | Removes termkit changes from both `~/.bashrc` and `~/.zshrc`. |
| `./install.sh` | Prints usage. |

### III. Repo Layout

```
termkit/
├── install.sh
├── configs/
│   ├── settings.conf              # your picks live here
│   ├── themes/{bash,zsh}/         # shell prompts
│   ├── fonts/*.ttf                # copied to ~/.local/share/fonts when enabled
│   ├── logo/*.txt                 # printed on shell start when enabled
│   └── aliases.sh                 # sourced when aliases are enabled
└── docs/
    ├── 01-guide-setup.md
    ├── 02-guide-settings.md
    └── 03-guide-extending.md
```

### IV. Uninstall

`./install.sh uninstall`:

- Removes the managed block from both `~/.bashrc` and `~/.zshrc` (whichever has it).
- Removes fonts under `~/.local/share/fonts/` matching files in `configs/fonts/`.
- Removes files under `~/.oh-my-zsh/custom/themes/` matching `configs/themes/zsh/*.zsh-theme`.

Fonts and themes from other sources are left alone. Backups at `~/.bashrc.termkit.bak` and `~/.zshrc.termkit.bak` are kept. To fully revert:

```
cp ~/.bashrc.termkit.bak ~/.bashrc
cp ~/.zshrc.termkit.bak  ~/.zshrc
```

## Contact & Support

<p style="font-size: 20px;"><strong>Cao Trong Phuoc</strong> - Software Engineer - Embedded Systems</p>

``` Note
Thank you for visiting this repository.
If you have any questions, suggestions, or feedback about this project or terminal customization, feel free to contact me directly.
```

<a href="https://github.com/caotrongphuoc">
  <img src="https://img.shields.io/badge/GitHub-caotrongphuoc-181717?style=for-the-badge&logo=github&logoColor=white"/>
</a>

<a href="https://www.linkedin.com/in/cao-trong-phuoc/">
  <img src="https://img.shields.io/badge/LinkedIn-Cao%20Trong%20Phuoc-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white"/>
</a>
