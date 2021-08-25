function untar --wraps='tar' \
        --description='Extracts a tarball.' \
        --argument file

    if test -z $file 2>/dev/null
        echo "Usage: untar file.tar.gz"
        return 1
    end

    # TODO: iterate files when no args, prompting before extract

    tar -zxvf $file
end
