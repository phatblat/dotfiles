#!/usr/bin/env fish
function fileowner \
    --description='Displays the owner of a file.' \
    --argument-names file

    if test -z "$file"
        echo "Usage: fileowner file"
        return 1
    end

    if is_mac
        ls -ld $file | string split --no-empty --fields 3 ' '
    else if is_linux
        stat --format=%U $file
    end
end
