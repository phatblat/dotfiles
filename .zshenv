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
