# Standalone two-line zsh prompt with git branch. Works without oh-my-zsh.
# Line 1:  green user@host   blue path   pink "git:<branch>" (only in a git repo)
# Line 2:  green ❯
#
# --- git branch detection ---
# vcs_info is a built-in zsh helper that fills $vcs_info_msg_0_ with repo info.
# It must be called before every prompt render via precmd().
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '  git:%b'   # %b = branch name

# --- prompt substitution ---
# PROMPT_SUBST tells zsh to expand $variables and $(commands) inside PROMPT
# each time it renders. Without it, $vcs_info_msg_0_ stays static (empty).
setopt PROMPT_SUBST

# --- PROMPT breakdown ---
#   %F{N}...%f   set 256-color foreground (N = 0..255); %f resets
#   %n           username
#   %m           short hostname
#   %~           working directory (with ~ for $HOME)
#   ${...}       variable expansion (needs PROMPT_SUBST)
#
# Colors picked here:
#   114 = green    75 = blue    176 = pink
#
# See `man zshmisc` -> EXPANSION OF PROMPT SEQUENCES for the full list.
PROMPT='%F{114}%n@%m%f  %F{75}%~%f%F{176}${vcs_info_msg_0_}%f
%F{114}❯%f '
