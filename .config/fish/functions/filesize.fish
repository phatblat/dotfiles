function filesize \
    --description="Prints size of file in bytes." \
    --argument-names file

    if test -z "$file"
        echo "Usage: filesize filename"
        return 1
    end

    if is_mac
        if is_coreutils
            # coreutils: --format=%s
            stat --format=%s $file
        else
            # macOS args: -f '%z'
            stat -f '%z' $file
        end
    else if is_linux
        stat --format=%s $file
    end
end
