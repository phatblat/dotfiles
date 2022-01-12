function pie \
    --description='Install pods for Example app.'

    bundle exec pod install \
        --project-directory=Example \
        $argv
end
