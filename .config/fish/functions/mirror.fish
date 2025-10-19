#!/usr/bin/env fish
# Reset the git staging area and working copy to mirror HEAD.
function mirror
    git reset --hard $argv
end
