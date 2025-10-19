#!/usr/bin/env fish
# Git reset using patch.
function rp
    git reset --patch $argv
end
