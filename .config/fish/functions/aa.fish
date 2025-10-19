#!/usr/bin/env fish
function aa \
    --description='Add all modified tracked files to git staging area.'

    git add --update $argv
end
