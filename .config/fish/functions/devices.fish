# List devices (simulators and connected hardware) that Xcode knows about.
function devices
    instruments -s devices $argv
end
