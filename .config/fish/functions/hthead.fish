#!/usr/bin/env fish
# Send an HTTP request using the HEAD method using burl.
function hthead
    burl -I $argv
end
