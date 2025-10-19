#!/usr/bin/env fish
# List all git branches.
function bra
    git branch -avv $argv
end
