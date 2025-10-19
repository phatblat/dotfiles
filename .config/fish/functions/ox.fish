#!/usr/bin/env fish
function ox \
    --description='Open Xcode project in the current dir.'
    open *.xcodeproj $argv
end
