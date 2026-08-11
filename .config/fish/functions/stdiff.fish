#!/usr/bin/env fish
# Show diff of a git stash.
function stdiff
    set -l stash "stash@{0}"
    if test (count $argv) -gt 0
        set stash $argv[1]
        set -e argv[1]
    end
    git diff "$stash^..$stash" $argv
end
