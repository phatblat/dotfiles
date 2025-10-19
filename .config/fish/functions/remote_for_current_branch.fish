#!/usr/bin/env fish
function remote_for_current_branch \
    --description='Displays the name of the remote for the current branch.'

    set current_branch (git rev-parse --abbrev-ref HEAD)
    config branch.$current_branch.remote
end
