#!/usr/bin/env fish
function dvc \
    --description='Create a docker volume'

    docker volume create $argv
end
