function auth \
    --description='Quick nave to KPAuth' \
    --argument-names platform

    set -l path ~/dev/mdk

    switch "$platform"
        case i ios \*
            set path "$path/ios"
        case a android
            set path "$path/android"
    end

    pushd "$path/KPAuth"
end
