# Run pod install through Bundler, updating repos beforehand.
function bpiru
    bundle exec "pod install --repo-update $argv"
end
