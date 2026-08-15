# termkit

Terminal setup kit for Linux. Ship a config, run one command. Bash and zsh.

## Quickstart

Install prerequisites for your target shell first — see [docs/setup.md](docs/setup.md).

```
git clone https://github.com/caotrongphuoc/termkit.git ~/termkit
cd ~/termkit
$EDITOR configs/settings.conf     # pick shell, theme, logo, aliases
./install.sh apply
```

Then open a new terminal, or `source ~/.bashrc` / `source ~/.zshrc`.

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
├── configs/
│   ├── settings.conf              # your picks live here
│   ├── themes/{bash,zsh}/         # shell prompts
│   ├── fonts/*.ttf                # copied to ~/.local/share/fonts when enabled
│   ├── logo/*.txt                 # printed on shell start when enabled
│   └── aliases.sh                 # sourced when aliases are enabled
└── docs/
    ├── setup.md                   # prerequisites per shell (start here)
    ├── settings.md                # settings.conf schema and apply behavior
    └── extending.md               # add your own theme, font, or logo
```

## Uninstall

`./install.sh uninstall`:

- Removes the managed block from both `~/.bashrc` and `~/.zshrc` (whichever has it).
- Removes fonts under `~/.local/share/fonts/` matching files in `configs/fonts/`.
- Removes files under `~/.oh-my-zsh/custom/themes/` matching `configs/themes/zsh/*.zsh-theme`.

Fonts and themes from other sources are left alone. Backups at `~/.bashrc.termkit.bak` and `~/.zshrc.termkit.bak` are kept. To fully revert:

```
cp ~/.bashrc.termkit.bak ~/.bashrc
cp ~/.zshrc.termkit.bak  ~/.zshrc
```
