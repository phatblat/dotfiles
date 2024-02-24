function nav \
    --description 'Quick nav to a dir. Creates dir if not present.' \
    --argument-names dir

    if test -z "$dir"
        error "Usage: nav dir"
        return 1
    end

    if test -d "$dir"
        pushd $dir
    else
        # Depends on custom mkdir function which includes pushd
        mkdir "$dir"
    end
end
