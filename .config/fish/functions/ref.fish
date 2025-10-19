#!/usr/bin/env fish
# Prints the symbolic ref for the given treeish.
function ref
    git symbolic-ref $argv
end
