#!/usr/bin/env fish
function dct \
    --description='Display the running processes of a docker container'

    docker container top $argv
end
