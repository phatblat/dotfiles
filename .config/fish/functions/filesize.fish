function filesize \
        --description="Prints size of file in bytes." \
        --argument-names file

    if test -z "$file"
        echo "Usage: filesize filename"
        return 1
    end

    if is_mac
        stat -c '%s' $file
    else if is_linux
        stat --format=%s $file
    end
end
