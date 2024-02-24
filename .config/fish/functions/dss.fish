function dss \
    --description 'Scale one or multiple replicated docker services'

    docker service scale $argv
end
