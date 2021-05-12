function fileowner \
    --description='Displays the owner of a file.' \
    --argument-names file

    if test -z "$file"
        echo "Usage: fileowner file"
        return 1
    end

    if is_mac
        if is_coreutils
            # coreutils: --format=%U
            stat --format=%U $file
        else
            # macOS args: -c '%U'
            # stat -c '%U' $file
            ls -ld $file | cut -d' ' -f3
        end
    else if is_linux
        stat --format=%U $file
    end
end
