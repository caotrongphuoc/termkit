# Simple oh-my-zsh theme: two-line prompt with git branch.
# Line 1:  green user@host   blue path   pink "git:<branch>" (only in a git repo)
# Line 2:  green ❯
#
# --- oh-my-zsh integration ---
# This file is copied to ~/.oh-my-zsh/custom/themes/ by `./install.sh apply`.
# You must set ZSH_THEME="simple" in ~/.zshrc BEFORE the oh-my-zsh source line.
#
# --- git branch detection ---
# vcs_info fills $vcs_info_msg_0_ with repo info. Register it via add-zsh-hook
# so we cooperate with oh-my-zsh's own precmd stack (do NOT override precmd()).
autoload -Uz vcs_info
autoload -Uz add-zsh-hook
add-zsh-hook precmd vcs_info
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
