#!/usr/bin/env fish
function chexe \
        --description='Set executable permissions' \
        --argument-names files
    if test -z "$files"
        set files *.sh
    end
    chmod +x $files
end
