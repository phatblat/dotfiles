#!/usr/bin/env fish
# Build Mac platform using Carthage. 
function cbmac
    carthage build --platform Mac $argv
end
