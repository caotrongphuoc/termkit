# Two-line bash prompt with git branch. Sourced by ~/.bashrc.
# Line 1:  green user@host   blue path   pink "git:<branch>" (only in a git repo)
# Line 2:  green ❯
#
# --- helper function ---
# parse_git_branch runs on every prompt render (via the $(...) inside PS1).
# It prints the current branch name, or nothing if we're not in a git repo.
parse_git_branch() {
    git branch --show-current 2>/dev/null
}

# --- PS1 breakdown ---
#   \[\e[38;5;Nm\]   set 256-color foreground (N = 0..255).
#                    \[...\] tells bash the enclosed bytes are non-printing
#                    so line-wrap math works.
#   \[\e[0m\]        reset color to default
#   \u               username
#   \h               short hostname
#   \w               full working directory
#   \n               newline (starts line 2)
#   $(...)           command substitution runs every prompt render
#   ❯                the prompt symbol on line 2 (any UTF-8 char works)
#
# Colors picked here:
#   114 = green    75 = blue    176 = pink
#
# Preview the whole 256-color palette in your terminal with:
#   for i in {0..255}; do printf '\e[38;5;%sm%3s\e[0m ' "$i" "$i"; done; echo
# shellcheck disable=SC2154  # $branch is assigned inside the same $(...) subshell
PS1='\[\e[38;5;114m\]\u@\h\[\e[0m\]  \[\e[38;5;75m\]\w\[\e[0m\]\[\e[38;5;176m\]$(branch=$(parse_git_branch); [ -n "$branch" ] && echo "  git:$branch")\[\e[0m\]\n\[\e[38;5;114m\]❯\[\e[0m\] '
