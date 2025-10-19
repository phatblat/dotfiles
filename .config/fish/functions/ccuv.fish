#!/usr/bin/env fish
# Update depencencies without building using Carthage with verbose output.
function ccuv
    ccu --verbose $argv
end
