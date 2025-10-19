#!/usr/bin/env fish
function current_branch \
    --description='Displays the current branch name.'

    git rev-parse --abbrev-ref HEAD $argv
end
