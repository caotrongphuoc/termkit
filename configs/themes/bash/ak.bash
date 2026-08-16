# Two-line bash prompt with git branch (256-color).
# Preview palette: for i in {0..255}; do printf '\e[38;5;%sm%3s\e[0m ' "$i" "$i"; done; echo
# TWEAK: run `grep -n TWEAK ak.bash` to jump between edit points.

parse_git_branch() { git branch --show-current 2>/dev/null; }

# TWEAK: colors — 114 green (user@host), 75 blue (path), 176 pink (branch).
# TWEAK: prompt symbol on line 2 — swap ❯ for $, ▶, →, or anything.
# shellcheck disable=SC2154  # $branch is assigned inside the same $(...) subshell
PS1='\[\e[38;5;114m\]\u@\h\[\e[0m\]  \[\e[38;5;75m\]\w\[\e[0m\]\[\e[38;5;176m\]$(branch=$(parse_git_branch); [ -n "$branch" ] && echo "  git:$branch")\[\e[0m\]\n\[\e[38;5;114m\]❯\[\e[0m\] '
