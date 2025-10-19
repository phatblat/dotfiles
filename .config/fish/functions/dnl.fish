#!/usr/bin/env fish
function dnl \
    --description='List docker networks'

    docker network ls $argv
end
