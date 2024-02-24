function createdirs \
    --description 'Creates a set of directories if they don\'t exist.'

    if test -z "$argv"
        echo "Usage: createdirs dir1 dir2 ..."
        return 1
    end

    for dir in $argv
        if not test -e $dir
            command mkdir -p $dir
        end
    end
end
