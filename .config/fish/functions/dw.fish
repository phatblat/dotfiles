#!/usr/bin/env fish
# Git diff with word diff.
function dw
    git diff --word-diff $argv
end
