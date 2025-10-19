#!/usr/bin/env fish
function dip \
    --description='Remove unused docker images, without confirmation'

    docker image prune --force $argv
end
