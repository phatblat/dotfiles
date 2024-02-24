function multipass-start \
    --description 'Starts the multipass service and GUI app'

    sudo launchctl load -w /Library/LaunchDaemons/com.canonical.multipassd.plist
    open -a Multipass
end
