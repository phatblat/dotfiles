#!/usr/bin/env fish
function surf \
    --description='Opens Windsurf' \
    --argument-names path

    if test -z $path
        windsurf .
    else
        windsurf $argv
    end
end
