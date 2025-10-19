#!/usr/bin/env fish
function dra \
    --description='Removes all stopped docker containers'

    echo "Running command to: Remove all stopped containers"
    set -l running_containers (docker container ls --all --quiet)
    if set --query running_containers[1]
        docker container rm $running_containers
    else
        echo "No containers found to remove"
    end
end
