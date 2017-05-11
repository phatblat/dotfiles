# Displays nginx process information.
function xstatus --wraps ps
    ps \
        # Columns
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
