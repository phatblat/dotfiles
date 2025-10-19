#!/usr/bin/env fish
# List hidden files
function ldot --wraps ls
    la -d .* $argv
end
