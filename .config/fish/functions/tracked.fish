#!/usr/bin/env fish
# Displays files tracked in the current git repo.
function tracked
    git ls-tree -r --name-only HEAD $argv
end
