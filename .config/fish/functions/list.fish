# Prints a list with each element on a separate line. Handy for returning a list
# from a function.
# https://github.com/fish-shell/fish-shell/issues/445
#
# Options:
#   -s Splits arguments on spaces.
function list \
        --description='Prints a list with each element on a separate line.'
    if test -z "$argv"
        echo "Usage: list [-s] 1 2 3 4 ..."
        return 1
    end

    set -l items $argv
    if test $argv[1] = -s
        if test (count $argv) -lt 2
            echo "Usage: list -s 1 2 3 4 ..."
            return 2
        end

        # Force split args on spaces
        set items (string split ' ' -- $argv[2..-1])
    end

    string join \n -- $items
end
