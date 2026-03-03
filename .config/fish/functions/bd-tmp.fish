#!/usr/bin/env fish
# Forcefully delete a branch from git.
function bd
    git branch -D $argv
end
