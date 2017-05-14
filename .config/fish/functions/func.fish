# Prints colorized, indented source of a loaded function.
function func \
        --argument-name name
    if test -z "$name"
        echo "Usage: func name"
        return 1
    else if not functions --query $name
        echo "$name does not exist"
        return 2
    end

    functions $name | fish_indent --ansi
end
