#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
#
# .zshenv
#
# .zshenv is always sourced. It often contains exported variables that should be available to other programs. For example, $PATH, $EDITOR, and $PAGER are often set in .zshenv. Also, you can set $ZDOTDIR in .zshenv to specify an alternative location for the rest of your zsh configuration.
#
# https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout/71258#71258
#
#-------------------------------------------------------------------------------

# echo ".zshenv"

source "$HOME/.cargo/env"

# Java
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="$JAVA_HOME/bin:$PATH"

export PATH="$PATH:$HOME/.puro/bin" # Added by Puro
export PATH="$PATH:$HOME/.puro/shared/pub_cache/bin" # Added by Puro
export PATH="$PATH:$HOME/.puro/envs/default/flutter/bin" # Added by Puro
export PURO_ROOT="/Users/phatblat/.puro" # Added by Puro
export PUB_CACHE="/Users/phatblat/.puro/shared/pub_cache" # Added by Puro
