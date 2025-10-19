#!/usr/bin/env fish
function tarls \
    --description='List contents of a tarball' \
    --argument-names file_name

    if test -z $file_name
        echo 'Usage: tarls [file_name]'
        return 1
    end

    tar -ztvf $file_name
end
