# List functions.
function fl --argument-names filter
    set -l all_funcs (functions)

    if test -z $filter
        echo $all_funcs\n
    else
        echo filter $filter
        echo $all_funcs\n | grep $filter
    end
end
