function mdk \
    --description 'Quick nav to MDK' \
    --argument-names platform
    set -l path ~/dev/mdk

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
