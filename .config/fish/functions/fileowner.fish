function fileowner \
        --description='Displays the owner of a file.' \
        --argument-names file

    if test -z "$file"
        echo "Usage: fileowner file"
        return 1
    end

    id -un (stat -f%u $file)
end
