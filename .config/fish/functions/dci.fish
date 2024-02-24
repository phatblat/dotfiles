function dci \
    --description 'Display detailed information on one or more docker containers'

    docker container inspect $argv
end
