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

    if test -n "$node_version"
        cat $node_version >$nvm_file
        return
    end

    if test -s $nvm_file
        cat $nvm_file
    else
        node --version
    end
end
