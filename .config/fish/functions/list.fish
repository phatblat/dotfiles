# Prints a list with each element on a separate line. Handy for returning a list
# from a function.
# https://github.com/fish-shell/fish-shell/issues/445
function list
    if test -z "$argv"
        echo "Usage: list 1 2 3 4 ..."
        return 1
    end

    string join \n $argv
end
