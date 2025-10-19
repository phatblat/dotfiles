#!/usr/bin/env fish
function dnuke \
    --description='Remove unused docker images not just dangling ones'

    docker system prune --all --force $argv
end
