#!/usr/bin/env fish
function dcstart \
    --description='Start one or more stopped docker containers'

    docker container start $argv
end
