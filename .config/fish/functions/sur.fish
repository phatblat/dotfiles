#!/usr/bin/env fish
# Update git submodules recursively.
function sur
    git submodule update --recursive $argv
end
