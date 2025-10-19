#!/usr/bin/env fish
# Erash fish functions.
function erase --wraps functions
    functions --erase $argv
end
