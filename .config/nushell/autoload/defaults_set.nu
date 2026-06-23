# Dependencies:
#   functions: none
#   builtins:  complete
#   externals: osascript sudo defaults systemsetup mdutil killall /usr/libexec/PlistBuddy chflags duti

# Bulk-set macOS system preferences (Finder, Dock, keyboard, Spotlight, Safari, Xcode, etc.) via defaults write
export def defaults_set [] {
    # Close any open System Preferences panes, to prevent them from overriding
    # settings we're about to change
    ^osascript -e 'tell application "System Preferences" to quit'

    # Ask for the administrator password upfront
    ^sudo --validate

    #
    # Login Screen
    #

    # Show system info on login screen
    ^defaults write com.apple.loginwindow AdminHostInfo HostName

    #
    # Keyboard
    #

    # Disable press-and-hold for keys in favor of key repeat
    ^defaults write -g ApplePressAndHoldEnabled -bool false

    # Set a blazingly fast keyboard repeat rate
    ^defaults write -g InitialKeyRepeat -int 13
    ^defaults write -g KeyRepeat -int 2

    # Enable full keyboard access for all controls
    ^defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    # Display ASCII control characters using caret notation in standard text views
    ^defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true

    # Disable Resume system-wide
    ^defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

    # Disable automatic termination of inactive apps
    ^defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

    # Disable automatic capitalization
    ^defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

    # Disable smart dashes
    ^defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # Disable automatic period substitution
    ^defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

    # Disable smart quotes
    ^defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

    # Disable auto-correct
    ^defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Disable "Do you want to enable Dictation?" prompt
    ^defaults write com.apple.HIToolbox AppleDictationAutoEnable -int 0

    # Set language and text formats
    ^defaults write NSGlobalDomain AppleLanguages -array "en" "es"
    ^defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
    ^defaults write NSGlobalDomain AppleMeasurementUnits -string "Inches"
    ^defaults write NSGlobalDomain AppleMetricUnits -bool false

    # Set the timezone
    ^sudo systemsetup -settimezone "America/Denver"

    #
    # Trackpad
    #

    ^defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    ^defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

    # Enable tap to click
    ^defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    ^defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    ^defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    #
    # Finder
    #

    # Add "Quit Finder" menu item and restart Finder
    ^defaults write com.apple.Finder QuitMenuItem -bool TRUE
    ^killall Finder

    # Show icons for hard drives, servers, and removable media on the desktop
    ^defaults write com.apple.Finder ShowHardDrivesOnDesktop -bool true
    ^defaults write com.apple.Finder ShowExternalHardDrivesOnDesktop -bool true
    ^defaults write com.apple.Finder ShowRemovableMediaOnDesktop -bool true
    ^defaults write com.apple.Finder ShowMountedServersOnDesktop -bool true

    # Home Dir as default new window location
    ^defaults write com.apple.Finder NewWindowTarget -string PfHm
    ^defaults write com.apple.Finder NewWindowTargetPath -string $"file:///($env.HOME)/"

    # Show all file extensions
    ^defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Finder: show status bar
    ^defaults write com.apple.finder ShowStatusBar -bool true

    # Finder: show path bar
    ^defaults write com.apple.finder ShowPathbar -bool true

    # Display full POSIX path as Finder window title
    ^defaults write com.apple.finder _FXShowPosixPathInTitle -bool false

    # Keep folders on top when sorting by name
    ^defaults write com.apple.finder _FXSortFoldersFirst -bool true

    # Disable extension change warning
    ^defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Suppress warning when file moved from iCloud Drive
    ^defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool false

    # Disable warning before emptying the Trash
    ^defaults write com.apple.finder WarnOnEmptyTrash -bool false

    # Enable AirDrop over every interface
    ^defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

    # Use list view in all Finder windows by default
    ^defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Hide the Tags section of the sidebar
    ^defaults write com.apple.Finder SidebarTagsSectionDisclosedState -bool false

    # Disable disk image verification
    ^defaults write com.apple.frameworks.diskimages skip-verify -bool true
    ^defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
    ^defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

    # Auto-open new Finder window when a volume is mounted
    ^defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
    ^defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
    ^defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

    ^defaults write com.apple.finder "ComputerViewSettings.ListViewSettings.WindowState.ShowSidebar" -bool true

    #
    # Desktop
    #

    let finder_plist = $"($env.HOME)/Library/Preferences/com.apple.finder.plist"

    # Show item info near icons
    ^/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" $finder_plist
    ^/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" $finder_plist
    ^/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" $finder_plist

    # Show item info to the right of the icons on the desktop
    ^/usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:labelOnBottom true" $finder_plist

    # Enable snap-to-grid
    ^/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" $finder_plist
    ^/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" $finder_plist
    ^/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" $finder_plist

    # Increase grid spacing
    ^/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" $finder_plist
    ^/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" $finder_plist
    ^/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" $finder_plist

    # Increase icon size
    ^/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 80" $finder_plist
    ^/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 80" $finder_plist
    ^/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 80" $finder_plist

    # QuickLook text selection
    ^defaults write com.apple.Finder QLEnableTextSelection -bool true

    # Show the ~/Library folder
    ^chflags nohidden $"($env.HOME)/Library"

    # Show the /Volumes folder
    ^sudo chflags nohidden /Volumes

    # Expand File Info panes
    ^defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true Privileges -bool true

    #
    # Dock
    #

    # Automatically hide and show the Dock
    ^defaults write com.apple.dock autohide -bool true

    # Make Dock icons of hidden applications translucent
    ^defaults write com.apple.dock showhidden -bool true

    # Remove the animation when hiding/showing the Dock
    ^defaults write com.apple.dock autohide-time-modifier -float 0

    # Remove the delay for Auto-Hide & Auto-Show of Dock
    ^defaults write com.apple.Dock autohide-delay -float 0
    ^defaults write com.apple.dock no-bouncing -bool true

    # Disable the warning before emptying the Trash (Dock)
    ^defaults write com.apple.finder WarnOnEmptyTrash -bool false

    #
    # Mission Control
    #

    # Disable automatically rearrange Spaces based on most recent use
    ^defaults write com.apple.dock mru-spaces -bool false

    # Group windows by application in Mission Control
    ^defaults write com.apple.dock expose-group-apps -bool true

    # Speed up Mission Control animations
    ^defaults write com.apple.dock expose-animation-duration -float 0.1

    #
    # Spotlight
    #

    # Disable indexing of Time Machine backup drive
    ^sudo mdutil -i off "/Volumes/ThunderBox"

    # Change indexing order and disable some search results
    ^defaults write com.apple.spotlight orderedItems -array '{"enabled" = 1;"name" = "APPLICATIONS";}' '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' '{"enabled" = 1;"name" = "DIRECTORIES";}' '{"enabled" = 1;"name" = "PDF";}' '{"enabled" = 1;"name" = "FONTS";}' '{"enabled" = 0;"name" = "DOCUMENTS";}' '{"enabled" = 0;"name" = "MESSAGES";}' '{"enabled" = 0;"name" = "CONTACT";}' '{"enabled" = 0;"name" = "EVENT_TODO";}' '{"enabled" = 0;"name" = "IMAGES";}' '{"enabled" = 0;"name" = "BOOKMARKS";}' '{"enabled" = 0;"name" = "MUSIC";}' '{"enabled" = 0;"name" = "MOVIES";}' '{"enabled" = 0;"name" = "PRESENTATIONS";}' '{"enabled" = 0;"name" = "SPREADSHEETS";}' '{"enabled" = 0;"name" = "SOURCE";}' '{"enabled" = 0;"name" = "MENU_DEFINITION";}' '{"enabled" = 0;"name" = "MENU_OTHER";}' '{"enabled" = 0;"name" = "MENU_CONVERSION";}' '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

    # Kill metadata server to load new settings
    do { ^killall mds } | complete | null
    # Enable indexing for the main volume
    do { ^sudo mdutil -i on "/" } | complete | null
    # Rebuild the index from scratch
    do { ^sudo mdutil -E "/" } | complete | null

    #
    # Time Machine
    #

    # Prevent Time Machine from prompting to use new hard drives as backup volume
    ^defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

    #
    # Remote Management
    #

    # Enable VNC access to the current macOS user's GUI session
    ^defaults write /Library/Preferences/com.apple.RemoteManagement VNCAlwaysStartOnConsole -bool true

    #
    # Mac App Store
    #

    # Enable the WebKit Developer Tools
    ^defaults write com.apple.appstore WebKitDeveloperExtras -bool true

    # Enable Debug Menu
    ^defaults write com.apple.appstore ShowDebugMenu -bool true

    # Enable the automatic update check
    ^defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

    # Check for software updates daily
    ^defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

    # Download newly available updates in background
    ^defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

    # Install System data files & security updates
    ^defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

    # Automatically download apps purchased on other Macs
    ^defaults write com.apple.SoftwareUpdate ConfigDataInstall -int 1

    # Turn on app auto-update
    ^defaults write com.apple.commerce AutoUpdate -bool true

    # Allow the App Store to reboot machine on macOS updates
    ^defaults write com.apple.commerce AutoUpdateRestartRequired -bool true

    #
    # Terminal
    #

    # Only use UTF-8 in Terminal.app
    ^defaults write com.apple.terminal StringEncodings -array 4

    # Enable Secure Keyboard Entry in Terminal.app
    ^defaults write com.apple.terminal SecureKeyboardEntry -bool true

    # Disable the annoying line marks
    ^defaults write com.apple.Terminal ShowLineMarks -int 0

    #
    # Safari
    #

    # Hide Safari's bookmark bar
    ^defaults write com.apple.Safari ShowFavoritesBar -bool false

    # Set up Safari for development
    ^defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
    ^defaults write com.apple.Safari IncludeDevelopMenu -bool true
    ^defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    ^defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true

    # Add a context menu item for showing the Web Inspector in web views
    ^defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

    # Disable the "Are you sure you want to open this application?" dialog
    ^defaults write com.apple.LaunchServices LSQuarantine -bool false

    # Invoke Duti to configure default apps
    ^duti $"($env.HOME)/.duti"

    #
    # Xcode
    #

    # Multiple cursors (cmd+click)
    ^defaults write com.apple.dt.Xcode PegasusMultipleCursorsEnabled -bool true

    # Show build times
    ^defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES

    # Show Xcode index count
    ^defaults write com.apple.dt.Xcode IDEIndexerActivityShowNumericProgress -bool true

    # Swift compiler new build system mode for better core utilization
    ^defaults write com.apple.dt.XCBuild EnableSwiftBuildSystemIntegration 1

    #
    # Tweetbot
    #
    ^defaults write com.tapbots.TweetbotMac OpenURLsDirectly YES

    #
    # TextMate
    #
    ^defaults write com.macromates.TextMate.preview fileBrowserSingleClickToOpen -bool true
}
