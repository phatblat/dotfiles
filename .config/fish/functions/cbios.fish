# Build iOS platform using Carthage.
function cbios
    carthage build --platform iOS $argv
end
