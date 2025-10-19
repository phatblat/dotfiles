#!/usr/bin/env fish
# Remove a git stash.
function stdrop
    git stash drop $argv
end
