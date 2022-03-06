function piev \
    --description='Install pods for Example app with verbose output.'

    pod install \
        --project-directory=Example \
        --verbose $argv
end
