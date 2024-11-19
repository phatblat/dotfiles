function bpiv \
    --description='Run a verbose pod install through Bundler.'

    bundle exec pod install --verbose $argv
end
