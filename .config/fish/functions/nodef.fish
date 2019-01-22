function nodef \
    --description='Removes default.profraw file.'

    if test -f default.profraw
        rm default.profraw
    end
end
