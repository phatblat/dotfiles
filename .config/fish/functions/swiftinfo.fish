#!/usr/bin/env fish
# Print information about the current Swift toolchain.
function swiftinfo
    xcrun --find swift; and swift --version $argv
end
