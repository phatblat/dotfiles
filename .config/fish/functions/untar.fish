function untar --wraps='tar' \
        --description='Extracts a tarball.' \
        --argument file_name

    if test -z $file_name 2>/dev/null
        error "Usage: untar file.tar.gz"
        return 1
    else if not test -f $file_name
        error "File not found: $file_name"
        return 2
    end

    set --local dir_name (file_base $file_name)
    if test -d $dir_name
        error "Extraction directory already exists: $dir_name"
        return 3
    end

    command mkdir $dir_name

    # -xzvf
    tar --extract --gunzip --verbose \
        --file $file_name \
        --directory $dir_name
end
