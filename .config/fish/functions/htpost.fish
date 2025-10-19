#!/usr/bin/env fish
# Send an HTTP request using the POST method using burl.
function htpost
    burl POST $argv
end
