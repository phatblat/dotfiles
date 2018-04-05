function untar --wraps='tar' \
        --description='Extracts a tarball.' \
        --argument file

    if test -z $file ^/dev/null
        echo "Usage: untar file.tar.gz"
        return 1
    end

    tar -zxvf $file
end