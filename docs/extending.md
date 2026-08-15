# Adding your own theme, font, or logo

## Bash theme

Drop `mytheme.bash` into `configs/themes/bash/`. Inside, set `PS1`, `LS_COLORS`, or anything else you want each new shell to run.

Then in `settings.conf`:

```
[shell]
name=bash

[theme]
name=mytheme
```

## Zsh standalone theme

Drop `mytheme.zsh` into `configs/themes/zsh/`. Inside, set `PROMPT`, `autoload -Uz vcs_info`, etc. Requires only zsh — no oh-my-zsh.

```
[shell]
name=zsh

[theme]
name=mytheme
```

## Zsh oh-my-zsh theme

Drop `mytheme.zsh-theme` into `configs/themes/zsh/`. Requires oh-my-zsh at `~/.oh-my-zsh/`.

Termkit copies the file to `~/.oh-my-zsh/custom/themes/` on apply. You then set `ZSH_THEME="mytheme"` manually in `~/.zshrc`, BEFORE the `source $ZSH/oh-my-zsh.sh` line.

## Font

Drop `MyFont.ttf` into `configs/fonts/`.

```
[font]
name=MyFont
install=true
```

## Logo

Drop `mylogo.txt` into `configs/logo/`.

```
[logo]
enabled=true
file=mylogo
use_fastfetch=false       # or true if you want fastfetch to render it
```
