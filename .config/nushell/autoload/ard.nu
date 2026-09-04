# Apple Remote Desktop (screen sharing) helpers.
# https://support.apple.com/en-us/HT201710

# Enable Apple Remote Desktop for all users with full privileges.
export def ard_enable [] {
    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart ...[
        -activate -configure -allowAccessFor -allUsers -privs -all -clientopts
        -setmenuextra -menuextra yes
    ]
}

# Restart ARD.
export def ard_restart [] {
    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent
}
