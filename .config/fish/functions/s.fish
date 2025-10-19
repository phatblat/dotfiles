#!/usr/bin/env fish
# Display abbreviated git status.
function s
    git status -sb $argv
end
