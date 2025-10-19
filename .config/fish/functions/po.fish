#!/usr/bin/env fish
function po \
    --description='List outdated pods.'

    pod outdated --no-repo-update $argv
end
