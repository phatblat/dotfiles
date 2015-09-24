#!/bin/bash -e
#-------------------------------------------------------------------------------
#
# xcode/alias.zsh
# Command-line aliases for Xcode
#
#-------------------------------------------------------------------------------

alias xccheck='~/.dotfiles/xcode/xccheck.sh'

function xclist() {
    local xcode filename

    # echo /Applications/Xcode*.app
    for xcode in /Applications/Xcode*.app; do
        # echo $xcode
        filename=$(basename $xcode)
        echo ${filename%.*};
    done
}
# export -f xclist
# alias xclist="echo /Applications/Xcode*.app"
