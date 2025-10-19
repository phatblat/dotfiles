#!/usr/bin/env fish
function diw \
    --description='Remove all Ping Identity docker images'

    echo "Running command to: Remove all Ping Identity Docker images"

    # Prune unused images
    dip

    if test -n "(docker images 'pingidentity/*' -q | sort | uniq)"
        docker image rm docker rmi --force (docker image ls --format '{{.Repository}} {{.ID}}' "pingidentity/*")
    else
        echo "***No Ping Identity images present to remove***"
    end
end
