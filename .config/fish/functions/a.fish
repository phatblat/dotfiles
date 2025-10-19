#!/usr/bin/env fish
function a \
    --description='Add files to git staging area.'

    git add $argv
end
