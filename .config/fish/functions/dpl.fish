function dpl \
    --description 'View output from docker containers'

    docker compose logs --follow $argv
end
