#!/usr/bin/env fish
# Stops nginx.
function xstop
    sudo nginx -s stop $argv
end
