#!/usr/bin/env fish
# Apply and remove the top git stash.
function stpop
    git stash pop $argv
end
