#!/usr/bin/env fish
function dvi \
    --description='Display detailed information on one or more docker volumes'

    docker volume inspect $argv
end
