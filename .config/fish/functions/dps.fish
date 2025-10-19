#!/usr/bin/env fish
function dps \
    --description='List docker containers'

    docker ps $argv
end
