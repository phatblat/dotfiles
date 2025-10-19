#!/usr/bin/env fish
function dcp \
    --description='Remove all stopped docker containers without confirmation'

    docker container prune --force
end
