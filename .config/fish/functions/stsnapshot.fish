#!/usr/bin/env fish
# Saves a dirty working copy as a stash.
function stsnapshot
    set current_date (date)
    git stash save "snapshot: $current_date"
    git stash apply "stash@{0}"
end
