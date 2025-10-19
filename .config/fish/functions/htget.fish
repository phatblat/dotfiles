#!/usr/bin/env fish
# Send an HTTP request using the GET method using burl.
function htget
    burl GET $argv
end
