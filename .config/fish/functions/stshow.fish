#!/usr/bin/env fish
# Show a git stash.
function stshow
    git stash show -p $argv
end
