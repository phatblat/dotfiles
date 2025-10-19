#!/usr/bin/env fish
function dvl \
    --description='List docker volumes'

    docker volume ls $argv
end
