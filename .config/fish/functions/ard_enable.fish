# https://support.apple.com/en-us/HT201710
function ard_enable \
    --description 'Enables Apple Remote Desktop'

    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
        -activate -configure -allowAccessFor -allUsers -privs -all -clientopts \
        -setmenuextra -menuextra yes
end
