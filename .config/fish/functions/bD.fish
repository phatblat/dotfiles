#!/usr/bin/env fish
# Forcefully delete a branch from git.
function bD
    git branch -D $argv
end
