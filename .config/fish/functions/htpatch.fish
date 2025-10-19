#!/usr/bin/env fish
# Send an HTTP request using the PATCH method using burl.
function htpatch
    burl PATCH $argv
end
