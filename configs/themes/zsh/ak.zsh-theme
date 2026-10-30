# vim:ft=zsh ts=2 sw=2 sts=2
#
# AK's oh-my-zsh theme. Fork of pixegami-agnoster, trimmed to git only.
# Upstream: https://github.com/pixegami/terminal-profile
# Original agnoster: https://gist.github.com/3712874
#
# To customize: run `grep -n TWEAK ak.zsh-theme` for edit points.
# Colors are 0..255. Preview: for i in {0..255}; do print -P "%F{$i}$i%f"; done


CURRENT_BG='NONE'

setopt promptsubst
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' get-revision true
zstyle ':vcs_info:*' check-for-changes true
# TWEAK: '+' = staged, '-' = unstaged. Any single char works.
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:*' unstagedstr '-'
zstyle ':vcs_info:*' formats ' %u%c'
zstyle ':vcs_info:*' actionformats ' %u%c'

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # TWEAK: no Nerd font? Use '>', '|', or '❯'.
  SEGMENT_SEPARATOR=$''
}

prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

prompt_context() {
  # TWEAK: bg 008, fg 010. Use "%n@%m" to show hostname too.
  prompt_segment 008 010 "%(!.%{%F{yellow}%}.)%n"
}

prompt_git() {
  (( $+commands[git] )) || return
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    # TWEAK: branch icon. Needs Nerd font. Fallback: '', 'git:'.
    PL_BRANCH_CHAR=$''
  }
  local ref dirty mode repo_path
  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    # TWEAK: dirty = yellow/black. clean = 014/002.
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment 014 002
    fi

    # TWEAK: markers shown while bisecting/merging/rebasing.
    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    vcs_info
    echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
  fi
}

# TWEAK: only fires for Anaconda. For plain venv, swap body to:
#   [[ -n $VIRTUAL_ENV ]] && prompt_segment black default "${VIRTUAL_ENV:t}"
prompt_virtualenv() {
  if [[ -n $CONDA_PROMPT_MODIFIER ]]; then
    prompt_segment black default ${CONDA_PROMPT_MODIFIER:1:-2}
  fi
}

prompt_status() {
  local symbols
  symbols=()
  # TWEAK: ✘ = failed cmd, ⚡ = root, ⚙ = bg jobs. Delete lines to hide.
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

prompt_head() {
  # TWEAK: top line. %~ = cwd. %64<..<%~%<< truncates over 64 chars.
  echo "\r               "
  echo "\r %{%F{7}%}[%64<..<%~%<<]"
}

# TWEAK: segment order. Comment out a line to hide it. Don't move RETVAL=$?.
build_prompt() {
  RETVAL=$?
  prompt_head
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_git
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
