#-------------------------------------------------------------------------------
#
# shell/antigen.zsh
# Antigen zsh plugin setup
# http://antigen.sharats.me
#
#-------------------------------------------------------------------------------

# Set cache and log to user-writable path
# ANTIGEN_BASE_PATH=${HOME}/tmp/antigen
# mkdir -p ${ANTIGEN_BASE_PATH}
# export _ANTIGEN_CACHE_PATH=${ANTIGEN_BASE_PATH}/.cache
# mkdir -p ${_ANTIGEN_CACHE_PATH}
# export _ANTIGEN_LOG_PATH=${ANTIGEN_BASE_PATH}/antigen.log

# Create highlighters dir to fix error:
# zsh-syntax-highlighting: highlighters directory '/Users/phatblat/tmp/antigen/.cache/highlighters' not found.
# zsh-syntax-highlighting: failed loading highlighters, exiting.o
# mkdir -p ${_ANTIGEN_CACHE_PATH}/highlighters

# Start up Antigen
#source "$(brew --prefix)/share/antigen/antigen.zsh"
#antigen use oh-my-zsh

# Override oh-my-zsh aliases
#unalias d  2>/dev/null && alias d='git diff'
#unalias po 2>/dev/null && alias po='pod outdated --no-repo-update'

# Antigen Bundles
# antigen bundle common-aliases
#antigen bundle phatblat/powerline-shell --branch=custom
# antigen bundle robbyrussell/oh-my-zsh plugins/ruby

# Antigen Themes
# antigen theme gnzh

# Add zsh-syntax-highlighting as last bundle fixes "zsh-syntax-highlighting: failed loading highlighters, exiting."
# https://github.com/zsh-users/zsh-syntax-highlighting/blob/0a9b347483ae653e95ed7ccb147a0db3644b6384/INSTALL.md#antigen
#antigen bundle zsh-users/zsh-syntax-highlighting

#antigen apply
