function path_add \
    --description='Prepends a folder to PATH.' \
    --argument-names dir_name

    if test -z dir_name
        echo 'Usage: path_add dir_name'
        return 1
    end

    if test -d "$dir_name"
        set -xg PATH \
            "$dir_name" \
            $PATH
    end
end
