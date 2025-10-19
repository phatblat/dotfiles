#!/usr/bin/env fish
function gpgrep \
    --description='Grep for gradle properties'
    gw properties | grep $argv
end
