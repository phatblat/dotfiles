function restore \
    --description 'Discards changes in the working tree.'

    if test -z "$argv"
        git restore .
    else
        git restore $argv
    end
end
