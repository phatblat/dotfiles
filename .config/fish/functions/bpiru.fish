function bpiru \
    --description='Run pod install through Bundler, updating repos beforehand.'

    bundle exec pod install --repo-update $argv
end
