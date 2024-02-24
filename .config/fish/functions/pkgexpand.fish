function pkgexpand \
    --description 'Expands a pkg file' \
    --argument-names package dest_dir

    if test -z $package
        echo 'Usage: pkgexpand package dest_dir'
        return 1
    end

    if test -z $dest_dir
        echo 'Usage: pkgexpand package dest_dir'
        return 2
    end

    pkgutil --expand "$package" "$dest_dir"
end
