#-------------------------------------------------------------------------------
#
# powerline.zsh
# Powerline configuration
#
#-------------------------------------------------------------------------------

# Powerline PS1 setup using milkbikis/powerline-shell
# NOTE: This must be called after anigen is primed in z_login.zsh for $ADOTDIR
function install_powerline_prompt() {
	POWERLINE_HOME="${ADOTDIR}/repos/https-COLON--SLASH--SLASH-github.com-SLASH-phatblat-SLASH-powerline-shell.git-PIPE-custom"

	function powerline_precmd() {
		PS1="$(${POWERLINE_HOME}/powerline-shell.py $? --shell zsh 2> /dev/null)"
	}

	function install_powerline_precmd() {
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
