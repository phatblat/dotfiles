# Bootstrap Carthage-managed dependencies for the iOS platform.
function cbootios
    carthage bootstrap --no-use-binaries --platform iOS $argv
end

