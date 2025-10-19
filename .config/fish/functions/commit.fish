#!/usr/bin/env fish
# Perform a git commit.
function commit
    git commit --verbose $argv
end
