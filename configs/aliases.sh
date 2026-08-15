# Sourced by your shell rc when [aliases] enabled=true in settings.conf.
# The `alias name='command'` syntax works identically in bash and zsh.
#
# Add your own below. To pick them up: open a new terminal (or run
# `source ~/.bashrc` / `source ~/.zshrc`). Re-running `./install.sh apply`
# is only needed to enable/disable the whole file, not to add new aliases.
#
# Notes:
# - single quotes '...' keep the command literal; use double quotes if you
#   want $variables expanded when the alias is defined (usually you don't).
# - list active aliases with `alias` (no args).
# - remove an alias with `unalias name`.

alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
