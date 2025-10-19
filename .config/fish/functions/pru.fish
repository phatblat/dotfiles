#!/usr/bin/env fish
function pru \
    --description='Update CococaPod repos.'

    pod repo update $argv
end
