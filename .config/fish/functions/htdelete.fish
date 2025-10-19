#!/usr/bin/env fish
# Send an HTTP request using the DELETE method using burl.
function htdelete
    burl DELETE $argv
end
