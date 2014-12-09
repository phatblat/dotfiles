# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
SEGMENT_SEPARATOR=''
SHOW_STASH_SEGMENT=1

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
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

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$user@%m"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local local_branch local_branch_symbol dirty tracking_branch mode inside_work_tree remote repo_path ahead displayed_ahead behind

  inside_work_tree=$(git rev-parse --is-inside-work-tree 2>/dev/null)
  if [[ "$inside_work_tree" != true ]]; then
    return
  fi

  repo_path=$(git rev-parse --git-dir 2>/dev/null)
  dirty=$(parse_git_dirty)

  # Stash segment
  if [[ $SHOW_STASH_SEGMENT -eq 1 ]]; then
      stash_size=$(git stash list 2> /dev/null | wc -l | tr -d ' ')
      if [[ stash_size -ne 0 ]]; then
          prompt_segment white black
          echo -n "+${stash_size}"
      fi
  fi

  # Local branch segment
  # Could also use `git name-rev --name-only HEAD`
  local_branch=$(git symbolic-ref HEAD 2> /dev/null) || ""
  if [[ -z $local_branch ]]; then
    # detached_head=true;
    local_branch="$(git show-ref --head -s --abbrev |head -n1 2> /dev/null)";
    local_branch_symbol="➦"
  else
    # detached_head=false;
    local_branch=${local_branch/refs\/heads\//}
    local_branch_symbol=""
  fi

  tracking_branch=$(git rev-parse --verify $local_branch@{upstream} --symbolic-full-name 2>/dev/null)
  # Strip off /refs/remotes/ prefix
  tracking_branch=${tracking_branch/refs\/remotes\/}
  if [[ -n ${tracking_branch} ]] ; then
    ahead=$(git rev-list $local_branch@{upstream}..HEAD 2>/dev/null | wc -l | tr -d ' ')
    displayed_ahead=" (+${ahead})"
    behind=$(git rev-list HEAD..$local_branch@{upstream} 2>/dev/null | wc -l | tr -d ' ')
  else
    ahead=""
    displayed_ahead=""
    behind=""
  fi

  if [[ -n $dirty ]]; then
    prompt_segment yellow black
  else
    prompt_segment green black
  fi

  echo -n "${local_branch_symbol} ${local_branch}${displayed_ahead}"

  if [[ -e "${repo_path}/BISECT_LOG" ]]; then
    mode=" <B>"
  elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
    mode=" >M<"
  elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
    mode=" >R>"
  fi

  setopt promptsubst
  autoload -Uz vcs_info

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' get-revision true
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:*' stagedstr '✚'
  zstyle ':vcs_info:git:*' unstagedstr '●'
  zstyle ':vcs_info:*' formats ' %u%c'
  zstyle ':vcs_info:*' actionformats ' %u%c'
  vcs_info
  echo -n "${vcs_info_msg_0_}"

  # Upstream branch segment
  if [[ -n $tracking_branch ]]; then
    if [ $behind -ne 0 ]; then
      prompt_segment magenta white
    else
      prompt_segment cyan black
    fi

    remote=$(git config branch.$local_branch.remote)
    tracking_branch_shortname=${tracking_branch/$remote\/}
    if [[ "$tracking_branch_shortname" == "$local_branch" ]]; then
      tracking_branch=""
    else
      tracking_branch="$tracking_branch "
    fi

    echo -n "$tracking_branch(-$behind)"
  fi
}

prompt_hg() {
  local rev status
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        prompt_segment green black
      fi
      echo -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -Eq "^\?"`; then
        prompt_segment red black
        st='±'
      elif `hg st | grep -Eq "^(M|A)"`; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green black
      fi
      echo -n "☿ $rev@$branch" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue black '%~'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_hg
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
