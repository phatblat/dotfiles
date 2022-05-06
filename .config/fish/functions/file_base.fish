function file_base \
    --description='Prints the base name of the file after dropping extension' \
    --argument-names file_name

    if test -z $file_name
        echo 'Usage: file_base [file]'
        return 1
    end

    echo (string split -m2 -r '.' "$file_name")[1]
end
