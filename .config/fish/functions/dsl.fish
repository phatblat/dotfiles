#!/usr/bin/env fish
function dsl \
    --description='List docker services'

    docker service ls $argv
end
