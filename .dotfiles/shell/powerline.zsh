#-------------------------------------------------------------------------------
#
# options.zsh
# Command-line options
#
#-------------------------------------------------------------------------------
export POWERLINE_HOME=/usr/local/lib/python2.7/site-packages/powerline
export POWERLINE_CONFIG_PATHS=( ~/.powerline )

export DEFAULT_USER="phatblat"

# Powerline
powerline-daemon -q
. ${POWERLINE_HOME}/bindings/zsh/powerline.zsh
