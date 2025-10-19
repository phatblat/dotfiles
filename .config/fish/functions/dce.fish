#!/usr/bin/env fish
function dce \
    --description='Executes a command in a running container'

    docker container exec --interactive --tty $argv
end
