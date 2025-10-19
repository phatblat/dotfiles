#!/usr/bin/env fish
function nv \
    --description='nv' \
    --argument-names node_version

    if not type -q nvm
        error "NVM is not installed."
        return 1
    end

    if not type -q node
        error "Nnode.js is not installed."
        return 2
    end

    set -l nvm_file .node-version

    if test -z $node_version
        # Print version
        if test -s $nvm_file
            cat $nvm_file
        else
            node --version
        end
        return
    end

    if test $node_version = "clear"
        echo -n 🔥
        rm -v $nvm_file
    else if test $node_version = "set"
        node --version >$nvm_file
        cat $nvm_file
    else if test -n "$node_version"
        cat $node_version >$nvm_file
    end
end
