# Update depencencies without building using Carthage.
function ccu
    carthage update --no-use-binaries --no-build $argv
end
