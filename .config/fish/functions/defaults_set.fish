#-------------------------------------------------------------------------------
#
# defaults_set.fish
#
# Sets macOS application preferences through User Defaults.
#
# References:
# - https://github.com/mathiasbynens/dotfiles/blob/master/.macos
# - https://github.com/kvpb/.files/blob/master/.macos1013
# - https://github.com/kvpb/.files/blob/9ef284f53a4ac65cb05203bb696027514a5c08bc/.osxmavericks
#
# WARNING: These (defaults) commands are relatively slow. The entire function
#          takes about 3 seconds to finish.
#
# The original idea (and a couple settings) were grabbed from:
#   https://raw.github.com/holman/dotfiles/master/osx/set-defaults.sh
#   https://github.com/mathiasbynens/dotfiles/blob/master/.osx
#
# '-g' and '-globalDomain' may be used as synonyms for NSGlobalDomain.
#
#-------------------------------------------------------------------------------
function defaults_set

    # Close any open System Preferences panes, to prevent them from overriding
    # settings we’re about to change
    osascript -e 'tell application "System Preferences" to quit'

    # Ask for the administrator password upfront
    sudo --validate

    # Keep-alive: update existing `sudo` time stamp until `.macos` has finished
    # bash:
    # while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    # fish (not working):
    # while true
    #     sudo --non-interactive true; sleep 60; kill -0 "$fish_pid" or exit &
    # end #^>/dev/null &

    #
    # Login Screen
    #

    # Show system info on login screen
    defaults write com.apple.loginwindow AdminHostInfo HostName

    #
    # Keyboard
    #

    # https://github.com/mathiasbynens/dotfiles/issues/687
    # Disable press-and-hold for keys in favor of key repeat.
    defaults write -g ApplePressAndHoldEnabled -bool false

    # Set a blazingly fast keyboard repeat rate
    defaults write -g InitialKeyRepeat -int 13  # normal minimum is 15 (225 ms)
    defaults write -g KeyRepeat -int 2          # normal minimum is 2 (30 ms)

    # Enable full keyboard access for all controls
    # (e.g. enable Tab in modal dialogs)
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    # Display ASCII control characters using caret notation in standard text views
    # Try e.g. `cd /tmp; unidecode "\x{0000}" > cc.txt; open -e cc.txt`
    defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true

    # Disable Resume system-wide
    defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

    # Disable automatic termination of inactive apps
    defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

    # Disable automatic capitalization as it’s annoying when typing code
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

    # Disable smart dashes as they’re annoying when typing code
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # Disable automatic period substitution as it’s annoying when typing code
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

    # Disable smart quotes as they’re annoying when typing code
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Disable "Do you want to enable Dication?" prompt after tapping ctrl or fn twice?
    # https://apple.stackexchange.com/questions/365048/disable-dictation-from-command-line
    defaults write com.apple.HIToolbox AppleDictationAutoEnable -int 0

    # Set language and text formats
    # Note: if you’re in the US, replace `EUR` with `USD`, `Centimeters` with
    # `Inches`, `en_GB` with `en_US`, and `true` with `false`.
    defaults write NSGlobalDomain AppleLanguages -array "en" "es"
    defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
    defaults write NSGlobalDomain AppleMeasurementUnits -string "Inches"
    defaults write NSGlobalDomain AppleMetricUnits -bool false

    # Set the timezone; see `sudo systemsetup -listtimezones` for other values
    sudo systemsetup -settimezone "America/Denver"

    #
    # Trackpad
    #

    # https://apple.stackexchange.com/questions/180620/enabling-both-trackpad-drag-lock-and-3-finger-drag-at-once
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true


    # Trackpad: enable tap to click for this user and for the login screen
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    #
    # Finder
    #

    # Add "Quit Finder" menu item
    defaults write com.apple.Finder QuitMenuItem -bool TRUE && killall Finder


    # Preferences > General
    # Show icons for hard drives, servers, and removable media on the desktop
    defaults write com.apple.Finder ShowHardDrivesOnDesktop -bool true
    defaults write com.apple.Finder ShowExternalHardDrivesOnDesktop -bool true
    defaults write com.apple.Finder ShowRemovableMediaOnDesktop -bool true
    defaults write com.apple.Finder ShowMountedServersOnDesktop -bool true

    # New Finder windows show:
    #
    # Set Desktop as the default location for new Finder windows
    # For other paths, use `PfLo` and `file:///full/path/here/`
    # defaults write com.apple.finder NewWindowTarget -string "PfDe"
    # defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"
    #
    # Home Dir
    defaults write com.apple.Finder NewWindowTarget -string PfHm
    defaults write com.apple.Finder NewWindowTargetPath -string "file:///$HOME/"

    # Preferences > Advanced
    # Show all file extensions
    # https://www.defaults-write.com/display-the-file-extensions-in-finder/
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Finder: show status bar
    defaults write com.apple.finder ShowStatusBar -bool true

    # Finder: show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    # Display full POSIX path as Finder window title
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool false

    # Keep folders on top when sorting by name
    defaults write com.apple.finder _FXSortFoldersFirst -bool true

    # https://www.defaults-write.com/disable-the-extension-change-warning-in-os-x-finder/
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Suppress wanring when file moved from iCloud Drive
    defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool false

    # https://www.defaults-write.com/disable-the-warning-before-emptying-the-trash/
    defaults write com.apple.finder WarnOnEmptyTrash -bool false

    # Use AirDrop over every interface. srsly this should be a default.
    # Enable AirDrop over Ethernet and on unsupported Macs running Lion
    defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

    # Always open everything in Finder's list view. This is important.
    # Use list view in all Finder windows by default
    # Four-letter codes for the other view modes:
    # - Nlsv: List View
    # - icnv: Icon View
    # - clmv: Column View
    # - Flwv: Cover Flow View
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Hide the Tags section of the sidebar
    defaults write com.apple.Finder SidebarTagsSectionDisclosedState -bool false

    # Disable disk image verification
    defaults write com.apple.frameworks.diskimages skip-verify -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

    # Automatically open a new Finder window when a volume is mounted
    defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
    defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
    defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

    defaults write com.apple.finder ComputerViewSettings.ListViewSettings.WindowState.ShowSidebar -bool true

    #
    # Desktop
    #

    # Show item info near icons on the desktop and in other icon views
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist

    # Show item info to the right of the icons on the desktop
    /usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:labelOnBottom true" ~/Library/Preferences/com.apple.finder.plist

    # Enable snap-to-grid for icons on the desktop and in other icon views
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

    # Increase grid spacing for icons on the desktop and in other icon views
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist

    # Increase the size of icons on the desktop and in other icon views
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist

    # QuickLook text selection
    defaults write com.apple.Finder QLEnableTextSelection -bool true

    # Show the ~/Library folder.
    chflags nohidden ~/Library

    # Show the /Volumes folder
    sudo chflags nohidden /Volumes

    # Expand the following File Info panes:
    # “General”, “Open with”, and “Sharing & Permissions”
    defaults write com.apple.finder FXInfoPanesExpanded -dict \
        General -bool true \
        OpenWith -bool true \
        Privileges -bool true

    #
    # Dock
    #

    # Automatically hide and show the Dock
    defaults write com.apple.dock autohide -bool true

    # Make Dock icons of hidden applications translucent
    defaults write com.apple.dock showhidden -bool true

    # Remove the animation when hiding/showing the Dock
    defaults write com.apple.dock autohide-time-modifier -float 0

    # Remove the Delay for Auto-Hide & Auto-Show of Dock
    defaults write com.apple.Dock autohide-delay -float 0

    # Disable the warning before emptying the Trash
    defaults write com.apple.finder WarnOnEmptyTrash -bool false

    #
    # Mission Control
    #

    # Disable automatically rearrange Spaces base on most recent use
    defaults write com.apple.dock mru-spaces -bool false

    # Group windows by application in Mission Control
    defaults write com.apple.dock expose-group-apps -bool true

    # Speed up Mission Control animations
    defaults write com.apple.dock expose-animation-duration -float 0.1

    #
    # Spotlight
    #

    # Disable indexing of Time Machine backup drive
    sudo mdutil -i off "/Volumes/ThunderBox"

    # Change indexing order and disable some search results
    # Yosemite-specific search results (remove them if you are using macOS 10.9 or older):
    # 	MENU_DEFINITION
    # 	MENU_CONVERSION
    # 	MENU_EXPRESSION
    # 	MENU_SPOTLIGHT_SUGGESTIONS (send search queries to Apple)
    # 	MENU_WEBSEARCH             (send search queries to Apple)
    # 	MENU_OTHER
    defaults write com.apple.spotlight orderedItems -array \
        '{"enabled" = 1;"name" = "APPLICATIONS";}' \
        '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
        '{"enabled" = 1;"name" = "DIRECTORIES";}' \
        '{"enabled" = 1;"name" = "PDF";}' \
        '{"enabled" = 1;"name" = "FONTS";}' \
        '{"enabled" = 0;"name" = "DOCUMENTS";}' \
        '{"enabled" = 0;"name" = "MESSAGES";}' \
        '{"enabled" = 0;"name" = "CONTACT";}' \
        '{"enabled" = 0;"name" = "EVENT_TODO";}' \
        '{"enabled" = 0;"name" = "IMAGES";}' \
        '{"enabled" = 0;"name" = "BOOKMARKS";}' \
        '{"enabled" = 0;"name" = "MUSIC";}' \
        '{"enabled" = 0;"name" = "MOVIES";}' \
        '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
        '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
        '{"enabled" = 0;"name" = "SOURCE";}' \
        '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
        '{"enabled" = 0;"name" = "MENU_OTHER";}' \
        '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
        '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
        '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
        '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
    # Load new settings before rebuilding the index
    killall mds > /dev/null 2>&1
    # Make sure indexing is enabled for the main volume
    sudo mdutil -i on / > /dev/null
    # Rebuild the index from scratch
    sudo mdutil -E / > /dev/null

    #
    # Time Machine
    #

    # Prevent Time Machine from prompting to use new hard drives as backup volume
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

    #
    # Remote Management
    #

    # Enable VNC access to the current macOS user's GUI session
    defaults write /Library/Preferences/com.apple.RemoteManagement VNCAlwaysStartOnConsole -bool true

    #
    # Mac App Store
    #

    # Enable the WebKit Developer Tools in the Mac App Store
    defaults write com.apple.appstore WebKitDeveloperExtras -bool true

    # Enable Debug Menu in the Mac App Store
    defaults write com.apple.appstore ShowDebugMenu -bool true

    # Enable the automatic update check
    defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

    # Check for software updates daily, not just once per week
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

    # Download newly available updates in background
    defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

    # Install System data files & security updates
    defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

    # Automatically download apps purchased on other Macs
    defaults write com.apple.SoftwareUpdate ConfigDataInstall -int 1

    # Turn on app auto-update
    defaults write com.apple.commerce AutoUpdate -bool true

    # Allow the App Store to reboot machine on macOS updates
    defaults write com.apple.commerce AutoUpdateRestartRequired -bool true

    #
    # Terminal
    #

    # Only use UTF-8 in Terminal.app
    defaults write com.apple.terminal StringEncodings -array 4

    # Enable Secure Keyboard Entry in Terminal.app
    # See: https://security.stackexchange.com/a/47786/8918
    defaults write com.apple.terminal SecureKeyboardEntry -bool true

    # Disable the annoying line marks
    defaults write com.apple.Terminal ShowLineMarks -int 0

    #
    # Safari
    #

    # Hide Safari's bookmark bar.
    defaults write com.apple.Safari ShowFavoritesBar -bool false

    # Set up Safari for development.
    defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

    # Add a context menu item for showing the Web Inspector in web views
    defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

    # Disable the “Are you sure you want to open this application?” dialog
    defaults write com.apple.LaunchServices LSQuarantine -bool false

    # Invoke Duti to configure default apps (installed by brew)
    duti ~/.duti

    #
    # Xcode
    #

    # Verbose codesign logging
    #defaults write com.apple.dt.Xcode DVTCodesigningAllTheThingsLogLevel 3

    # Multiple cursors (cmd+click)
    # https://twitter.com/dmartincy/status/988094014804160514
    defaults write com.apple.dt.Xcode PegasusMultipleCursorsEnabled -bool true

    # Show build times - http://stackoverflow.com/questions/1027923/how-to-enable-build-timing-in-xcode#answer-2801156
    defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES

    # Show xcode index count
    defaults write com.apple.dt.Xcode IDEIndexerActivityShowNumericProgress -bool true

    # Xcode 13.3 beta 1 Swift compiler new mode that better utilizes available
    # cores, resulting in faster builds for Swift projects.
    defaults write com.apple.dt.XCBuild EnableSwiftBuildSystemIntegration 1

    #
    # Tweetbot
    #
    defaults write com.tapbots.TweetbotMac OpenURLsDirectly YES

    #
    # TextMate
    #
    defaults write com.macromates.TextMate.preview fileBrowserSingleClickToOpen -bool true
end
