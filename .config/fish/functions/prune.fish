#!/usr/bin/env fish
function prune \
    --description='Prune obsolete remote branches on the given remote.'

    git remote prune $argv
end
