function kpm \
    --description 'Quick dir navigation to kpmobile' \
    --argument-names platform
    set -l path ~/dev/kpmobile

    if test -n "$platform"
        switch $platform
            case i ios
                set path "$path/ios"
            case a android
                set path "$path/android"
        end
    end

    pushd $path
end
