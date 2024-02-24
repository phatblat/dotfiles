function dpd \
    --description 'Stops containers and removes containers, networks, volumes, and images created by `up`.'

    docker compose down $argv
end
