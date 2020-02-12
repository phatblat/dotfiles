function fileowner \
    --description='Displays the owner of a file.' \
    --argument-names file

    if test -z "$file"
        echo "Usage: fileowner file"
        return 1
    end

    if is_mac
        # Stock macOS
        # id -un (stat -f%u $file)

        # macOS args: -c '%U'
        # coreutils: --format=%U

        stat --format=%U $file
    else if is_linux
        stat --format=%U $file
    end
end
