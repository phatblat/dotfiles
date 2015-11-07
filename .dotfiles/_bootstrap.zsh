#!/usr/bin/env zsh
#
# Entry point for sourcing modularized zsh profile files
#
# topic/*.zsh: Any files ending in .zsh get loaded into your environment.

# This script is symlinked into $HOME as .zshrc.
# user_home is derived from the .zshrc location so that this script
# can be tested on CI
user_home=$( cd "$( dirname "$0" 2>/dev/null )" && pwd )

pushd $user_home/.dotfiles > /dev/null 2>&1

for dir in *
do
    if [ -d "$dir" ] ; then
        pushd "$dir" > /dev/null
        for file in *.zsh
        do
            if [ -f "$file" ]; then
                source "$file"
            fi
        done
        popd > /dev/null
    fi
done

popd > /dev/null 2>&1
