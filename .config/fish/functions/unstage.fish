function unstage --description='Clears changes out of the git index.'
    if test -z "$argv"
        reset .
    else
        reset $argv
    end
end
