# spotlight_reload - Reloads Spotlight which triggers a re-index
export def spotlight_reload [] {
    # https://ss64.com/osx/mdutil.html
    # -a             Apply command to all stores on all volumes.
    # -i (on|off)    Turn indexing on or off.
    ^sudo mdutil -a -i off

    ^sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
    ^sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist

    ^sudo mdutil -a -i on
}
