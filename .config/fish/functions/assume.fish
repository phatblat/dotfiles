#!/usr/bin/env fish
function assume \
    --description='Ignore changes to the given files.'

    git update-index --assume-unchanged $argv
end
