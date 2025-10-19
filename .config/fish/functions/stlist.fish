#!/usr/bin/env fish
# List git stashes.
function stlist
    git stash list $argv
end
