#!/usr/bin/env fish
# Build all platforms using Carthage with verbose output.
function cballv
    cball --verbose $argv
end
