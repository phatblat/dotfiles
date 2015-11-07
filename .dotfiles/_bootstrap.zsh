#!/usr/bin/env zsh
#
# Entry point for sourcing modularized zsh profile files
#
# topic/*.zsh: Any files ending in .zsh get loaded into your environment.

pushd ~/.dotfiles > /dev/null 2>&1

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
