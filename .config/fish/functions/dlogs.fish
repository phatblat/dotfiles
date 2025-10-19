#!/usr/bin/env fish
function dlogs \
    --description='Fetch the logs of a docker container'

    docker logs --follow $argv
end
