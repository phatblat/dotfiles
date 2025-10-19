#!/usr/bin/env fish
# Select a different version of Xcode.
function xcss
    sudo xcode-select --switch $argv
end
