function kpm --argument-names platform --description='Quick dir navigation to kpmobile'
    set -l path ~/dev/kpmobile

    switch $platform
    case i ios
        set path "$path/ios"
    case a android
        set path "$path/android"
    end
    
    pushd $path
end
