#!/usr/bin/env fish
function xcb \
    --description='Alias for xcodebuild' \
    --wraps=xcodebuild

    xcodebuild $argv
end
