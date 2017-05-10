# List functions.
function fl --argument-names filter
    if test -n $filter
        echo (functions)\n | grep $filter
        return 0
    end

    echo (functions)\n
end
