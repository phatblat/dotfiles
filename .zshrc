#!/usr/bin/env zsh
#
# Entry point for sourcing modularized zsh profile files
#
# bin/: Anything in bin/ will get added to your $PATH and be made available everywhere.
# topic/*.zsh: Any files ending in .zsh get loaded into your environment.
# topic/path.zsh: Any file named path.zsh is loaded first and is expected to setup $PATH or similar.
# topic/completion.zsh: Any file named completion.zsh is loaded last and is expected to setup autocomplete.
# topic/*.symlink: Any files ending in *.symlink get symlinked into your $HOME. This is so you can keep all of those versioned in your dotfiles but still keep those autoloaded files in your home directory. These get symlinked in when you run script/bootstrap.

pushd .dotfiles > /dev/null 2>&1

for dir in *
do
    # echo $dir
    # Skip the bin dir
    # [ $dir == "bin" ] && continue
    if [ -d "$dir" ] ; then
        pushd "$dir" > /dev/null
        for file in *.zsh
        do
            if [ -f "$file" ]; then
                # echo "Sourcing $file"
                source "$file"
            fi
        done
        popd > /dev/null
    fi
done

popd > /dev/null 2>&1

# Re-source oh-my-zsh.zsh to fix PROMPT
source .dotfiles/shell/oh-my-zsh.zsh
