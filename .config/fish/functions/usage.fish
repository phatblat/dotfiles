#!/usr/bin/env fish
function usage \
    --description='Show disk usage for a directory' \
    --argument-names path

    if test -z $path
        set path "."
    end

    du -hs $path
end
