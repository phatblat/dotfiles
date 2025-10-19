#!/usr/bin/env fish
# List functions.
function fl --argument-names filter
    set -l all_funcs (functions)

    if test -z $filter
        # String join removes trailing \n and strips leading space
        string join \n $all_funcs
    else
        echo Functions matching filter:
        echo $all_funcs\n | grep $filter
    end
end
