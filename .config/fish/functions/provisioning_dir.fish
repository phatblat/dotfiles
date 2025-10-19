#!/usr/bin/env fish
# Open the Provisioning Profiles directory in Finder.
function provisioning_dir
    open "$HOME/Library/MobileDevice/Provisioning Profiles" $argv
end
