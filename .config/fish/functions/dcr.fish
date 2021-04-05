function dcr \
    --description='Remove one or more running docker containers'

    docker container rm --force $argv
end
