#!/usr/bin/env fish
# Build all platforms using Carthage.
function cball
    carthage build --platform all $argv
end
