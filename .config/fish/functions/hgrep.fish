#!/usr/bin/env fish
function hgrep \
    --description='Grep command history'

    history | grep $argv
end
