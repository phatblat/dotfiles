#!/usr/bin/env fish
function dnr \
    --description='Remove one or more docker networks'

    docker network rm $argv
end
