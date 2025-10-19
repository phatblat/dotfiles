#!/usr/bin/env fish
# Send an HTTP request using the PUT method using burl.
function htput
    burl PUT $argv
end
