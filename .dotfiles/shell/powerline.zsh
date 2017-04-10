#-------------------------------------------------------------------------------
#
# powerline.zsh
# Powerline configuration
#
#-------------------------------------------------------------------------------

# Powerline PS1 setup using milkbikis/powerline-shell
# NOTE: This must be called after anigen is primed in z_login.zsh for $ADOTDIR
function install_powerline_prompt {
  # Antigen v1
  # POWERLINE_HOME="${ADOTDIR}/repos/https-COLON--SLASH--SLASH-github.com-SLASH-phatblat-SLASH-powerline-shell.git-PIPE-custom"
  # Antigen v2
  POWERLINE_HOME="${ADOTDIR}/bundles/phatblat/powerline-shell-custom"

  function powerline_precmd {
    PS1="$(${POWERLINE_HOME}/powerline-shell.py $? --colorize-hostname --shell zsh --cwd-max-depth 5 2> /dev/null)"
  }

  function install_powerline_precmd {
    for s in "${precmd_functions[@]}"; do
      if [ "$s" = "powerline_precmd" ]; then
        return
      fi
    done
    precmd_functions+=(powerline_precmd)
  }

  if [ "$TERM" != "linux" ]; then
    install_powerline_precmd
  fi
}

alias powerlinetest='echo "⮀ ± ⭠ ➦ ✔ ✘ ⚡"'
