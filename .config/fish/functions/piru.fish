#!/usr/bin/env fish
function piru \
    --description='Install pods after updating repos.'

    pod install --repo-update $argv
end
