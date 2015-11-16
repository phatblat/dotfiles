#-------------------------------------------------------------------------------
#
# powerline.zsh
# Powerline configuration
#
#-------------------------------------------------------------------------------

# Powerline PS1setup using milkbikis/powerline-shell
# NOTE: This must be called after anigen is primed in z_login.zsh for $ADOTDIR
function install_powerline_prompt() {
	POWERLINE_HOME="${ADOTDIR}/repos/https-COLON--SLASH--SLASH-github.com-SLASH-milkbikis-SLASH-powerline-shell.git"

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

# Old, manual setup

# if [ -d /usr/local/lib/python2.7/site-packages/powerline ] ; then
# 	export POWERLINE_HOME=/usr/local/lib/python2.7/site-packages/powerline
# elif [ -d ${HOME}/Library/Python/2.7/lib/python/site-packages/powerline ] ; then
# 	export POWERLINE_HOME=${HOME}/Library/Python/2.7/lib/python/site-packages/powerline
# else
# 	echo "Powerline is not installed. See http://computers.tutsplus.com/tutorials/getting-spiffy-with-powerline--cms-20740"
# fi
#
# export POWERLINE_CONFIG_PATHS=${HOME}/.powerline
#
# export DEFAULT_USER="phatblat"
#
# # Powerline
# powerline-daemon -q
# . ${POWERLINE_HOME}/bindings/zsh/powerline.zsh
#
# alias powerlinetest='echo "⮀ ± ⭠ ➦ ✔ ✘ ⚡"'
