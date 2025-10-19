#!/usr/bin/env fish
# Perform a git diff
function diff
    git diff --color $argv | diff-so-fancy
end
