# Run a verbose pod install through Bundler.
function bpiv
    bundle exec pod install --verbose $argv
end
