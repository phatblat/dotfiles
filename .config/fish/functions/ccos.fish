#!/usr/bin/env fish
function ccos \
        --description='Checkout source of dependencies using Carthage over SSH.'

    cco --use-ssh $argv
end
