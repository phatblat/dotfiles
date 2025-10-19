#!/usr/bin/env fish
# https://support.apple.com/en-us/HT201710
function ard_restart \
    --description='Restart ARD'

    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
        -restart -agent
end
