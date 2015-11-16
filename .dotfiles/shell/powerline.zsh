#-------------------------------------------------------------------------------
#
# powerline.zsh
# Powerline configuration
#
#-------------------------------------------------------------------------------

# TODO: Relocate powerline setup from shell/z_login.zsh to here

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
