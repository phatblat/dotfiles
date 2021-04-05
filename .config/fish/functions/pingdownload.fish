function pingdownload \
    --description='Downloads Ping DevOps tools'

    docker run --env-file ~/.pingidentity/devops --rm -v ~/Downloads:/tmp pingidentity/pingdownloader $argv
end
