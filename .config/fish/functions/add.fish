#!/usr/bin/env fish
function add \
    --description='Add files to git staging area.'

    git add $argv
end
