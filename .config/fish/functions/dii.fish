#!/usr/bin/env fish
function dii \
    --description='Display detailed information on one or more docker images'

    docker image inspect $argv
end
