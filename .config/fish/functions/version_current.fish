#!/usr/bin/env fish
function version_current \
    --description='Displays Xcode project version information.'

    echo (version_market)" ("(version_build)")"
end
