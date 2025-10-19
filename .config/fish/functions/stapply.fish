#!/usr/bin/env fish
# Apply a git stash.
function stapply
    git stash apply $argv
end
