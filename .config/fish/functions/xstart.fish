#!/usr/bin/env fish
# Starts nginx.
function xstart
    sudo nginx $argv
    xstatus
end
