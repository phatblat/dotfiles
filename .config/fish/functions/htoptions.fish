#!/usr/bin/env fish
# Send an HTTP request using the OPTIONS method using burl.
function htoptions
    burl OPTIONS $argv
end
