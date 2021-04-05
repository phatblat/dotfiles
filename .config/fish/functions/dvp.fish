function dvp \
    --description='Remove all unused local docker volumes, without confirmation'

    docker volume prune --force $argv
end
