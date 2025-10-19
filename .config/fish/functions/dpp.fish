#!/usr/bin/env fish
function dpp \
    --description='List docker containers'

    docker compose ps $argv
end
