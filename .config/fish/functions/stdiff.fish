#!/usr/bin/env fish
# Show diff of a git stash.
# Usage: stdiff [n]  (defaults to 0, the most recent stash)
function stdiff
    set -l n 0
    if test (count $argv) -gt 0
        set n $argv[1]
        set -e argv[1]
    end
    set -l stash "stash@{$n}"
    git diff "$stash^..$stash" $argv
end
