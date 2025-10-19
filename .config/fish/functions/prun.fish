#!/usr/bin/env fish
# Show what remote branches need to be pruned for the given remote.
function prun
    git remote prune --dry-run $argv
end
