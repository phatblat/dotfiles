#!/usr/bin/env fish
# Alias for `git log`.
function log
    git log --pretty=fuller $argv
end
