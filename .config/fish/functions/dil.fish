#!/usr/bin/env fish
function dil \
    --description='List docker images'

    docker images $argv
end
