function dsr \
    --description 'Remove one or more docker services'

    docker service rm $argv
end
