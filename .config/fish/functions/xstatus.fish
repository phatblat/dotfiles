#!/usr/bin/env fish
# Displays nginx process information.
function xstatus --wraps ps
    psgrep nginx
    return

    ps \
        -o user \
        -o pid \
        -o '%cpu' \
        -o '%mem' \
        -o time \
        -o start \
        -o etime \
        -o command=COMMAND \
        -p %nginx $argv
end
