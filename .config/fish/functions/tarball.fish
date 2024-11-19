function tarball --wraps='tar' \
        --description='Creates a tarball.' \
        --argument file_or_dir

    if test -z $file_or_dir 2>/dev/null
        echo "Usage: tarball file_or_dir"
        return 1
    end

    tar -zcvf $file_or_dir.tar.gz $file_or_dir
end
