# Settings and apply behavior

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

Values for `theme.name`, `font.name`, and `logo.file` are basenames without extension — termkit appends the right extension based on shell / file type.

## What apply does

### shell=bash

- Backs up `~/.bashrc` to `~/.bashrc.termkit.bak` on the first run.
- Appends a managed block that sources the theme, prints the logo, and sources aliases.

### shell=zsh

- Same, but writes to `~/.zshrc` and `~/.zshrc.termkit.bak`.
- If the theme is a `.zsh-theme` file, copies it to `~/.oh-my-zsh/custom/themes/<name>.zsh-theme` and reminds you to set `ZSH_THEME=<name>` yourself. Standalone `.zsh` themes are sourced from the managed block directly.

### Common to both

- Re-running `apply` strips the old managed block and writes a new one — never stacks duplicates.
- If `[font] install=true`, the `.ttf` is copied to `~/.local/share/fonts/` and `fc-cache -f` runs.
- Anything else in your shell rc is left alone.

## Managed block markers

```
# >>> termkit start >>>
# ...
# <<< termkit end <<<
```
