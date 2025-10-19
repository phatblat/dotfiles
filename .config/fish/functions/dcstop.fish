#!/usr/bin/env fish
function dcstop \
    --description='Stop one or more running docker containers'

    docker container stop $argv
end
