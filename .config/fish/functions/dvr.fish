function dvr \
    --description='Remove one or more volumes. You cannot remove a volume that is in use by a container.'

    docker volume rm $argv
end
