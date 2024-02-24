function dir \
    --description 'Remove one or more docker images, forcefully'

    docker image rm --force $argv
end
