#!/usr/bin/env fish
# Stop ignoring changes to the given files.
function unassume
    git update-index --no-assume-unchanged $argv
end
