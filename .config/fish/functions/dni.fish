#!/usr/bin/env fish
function dni \
    --description='Display detailed information on one or more docker networks'

    docker network inspect $argv
end
