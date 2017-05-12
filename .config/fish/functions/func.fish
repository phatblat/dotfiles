# Functions alias.
function func --argument name
    if test -z "$name"
        echo "Usage: func name"
        return 1
    end

    functions $name | fish_indent
end
