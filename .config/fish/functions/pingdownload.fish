function pingdownload \
    --description='Downloads Ping DevOps tools'

    docker run \
        --env-file ~/.pingidentity/devops \
        --rm \
        --volume ~/Downloads:/tmp \
        pingidentity/pingdownloader \
        $argv
end
