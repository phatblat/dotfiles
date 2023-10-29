function unstage \
    --description='Restores files in the git index from HEAD.'

    if test -z "$argv"
        git restore --staged .
    else
        git restore --staged $argv
    end
end
