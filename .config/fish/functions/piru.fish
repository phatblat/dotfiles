function piru \
    --description='Install pods after updating repos.'

    bundle exec pod install --repo-update $argv
end
