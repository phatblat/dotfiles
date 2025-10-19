#!/usr/bin/env fish
function xcdevices \
    --description 'List Xcode simulators and connected devices.'
    xcrun xctrace list devices $argv
end
