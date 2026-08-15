# Standalone two-line zsh prompt with git branch. Works without oh-my-zsh.
# Colors match the bash git-branch theme: green user@host, blue path, pink branch.

autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '  git:%b'

setopt PROMPT_SUBST
PROMPT='%F{114}%n@%m%f  %F{75}%~%f%F{176}${vcs_info_msg_0_}%f
%F{114}❯%f '
