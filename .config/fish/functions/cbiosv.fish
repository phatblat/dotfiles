#!/usr/bin/env fish
# Build iOS platform using Carthage with verbose output.
function cbiosv
    cbios --verbose $argv
end
