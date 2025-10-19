#!/usr/bin/env fish
# Build iOS platform using Carthage with verbose output.
function cbmacv
    cbmac --verbose $argv
end
