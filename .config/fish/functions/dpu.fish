function dpu \
    --description 'Builds, (re)creates, starts, and attaches to containers for a service.'

    docker compose up --detach $argv
end
