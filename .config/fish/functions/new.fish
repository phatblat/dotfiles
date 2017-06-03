# List all new commits have been created with the previous command, such as after a pull.
function new --argument-names commit
    if test -z $commit
        echo "Usage: new <commit>"
        return 1
    end

    git log $commit@{1}..$commit@{0} "$argv"
end

