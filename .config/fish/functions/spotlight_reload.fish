function spotlight_reload \
    --description='Reloads Spotlight which triggers a re-index'

    spotlight_disable

    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist

    spotlight_enable
end
