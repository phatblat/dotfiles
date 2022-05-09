function find_file \
    --description='Finds files under the given base_dir (defaults to PWD).' \
    --argument-names file_name base_dir

    if test -z $file_name
        echo "Missing file name"
        echo "Usage: find_file file.yml /base/dir"
        return 1
    end

    mdfind -name $file_name
    echo

    if test -z $base_dir
        set base_dir .
    end

    if not test -e $base_dir
        echo "'$base_dir' does not exist"
        return 2
    end

    echo "file_name: $file_name"
    echo "base_dir: $base_dir"
    echo "-----------------------------------"

    find "$base_dir" -name "*$file_name*" -print 2>/dev/null
end
