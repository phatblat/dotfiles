#!/usr/bin/env fish
function merge-base --wraps='git'
    git merge-base $argv
end
