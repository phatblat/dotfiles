function dnp \
    --description 'Remove all unused docker networks, without confirmation'

    docker network prune --force $argv
end
