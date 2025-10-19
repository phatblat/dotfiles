#!/usr/bin/env fish
function poe \
    --description='Show outdated pods for example app'

    pod outdated \
        --project-directory=Example \
        $argv
end
