# List devices (simulators and connected hardware) that Xcode knows about.
function devices \
    --description='List simulators and connected devices.'
    xcrun simctl list devices $argv
end
