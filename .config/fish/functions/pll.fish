#!/usr/bin/env fish
function pll \
    --description='Lint a pod library in the current directory.'

    pod lib lint $argv
end
