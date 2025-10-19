#!/usr/bin/env fish
# Repeats a character a fixed number of times.
function repeatchar --argument-names char length
    if test -z $char
        echo "Usage: repeatchar - 80"
        return 1
    end

    if test -z $length
        set length 80
    end

    printf '%*s\n' $length "" | tr ' ' $char
end
