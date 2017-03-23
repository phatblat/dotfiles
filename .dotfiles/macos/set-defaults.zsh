#-------------------------------------------------------------------------------
#
# macos/set-defaults.zsh
#
# The original idea (and a couple settings) were grabbed from:
#   https://raw.github.com/holman/dotfiles/master/osx/set-defaults.sh
#   https://github.com/mathiasbynens/dotfiles/blob/master/.osx
#
# '-g' and '-globalDomain' may be used as synonyms for NSGlobalDomain.
#
#-------------------------------------------------------------------------------

#
# Keyboard
#
defaults write -g InitialKeyRepeat -int 15 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)

#
# Finder
#

# Disable press-and-hold for keys in favor of key repeat.
defaults write -g ApplePressAndHoldEnabled -bool false

# Use AirDrop over every interface. srsly this should be a default.
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

# Always open everything in Finder's list view. This is important.
defaults write com.apple.Finder FXPreferredViewStyle Nlsv

# Show the ~/Library folder.
chflags nohidden ~/Library

# Set a really fast key repeat.
defaults write NSGlobalDomain KeyRepeat -int 0

# Set the Finder prefs for showing a few different volumes on the Desktop.
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

#
# Dock
#

# Remove the Delay for Auto-Hide & Auto-Show of Dock
defaults write com.apple.Dock autohide-delay -float 0

#
# Safari
#

# Hide Safari's bookmark bar.
defaults write com.apple.Safari ShowFavoritesBar -bool false

# Set up Safari for development.
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

#
# Mail
#
# Disable OSX Mail app auto loading (malicious) remote content in e-mails
defaults write com.apple.mail-shared DisableURLLoading -bool true

#  - http://furbo.org/2014/09/03/xcode-vs-gatekeeper/
alias ungate='xattr -d com.apple.quarantine '

# QuickLook text selection
defaults write com.apple.finder QLEnableTextSelection -bool TRUE

# Invoke Duti to configure default apps
# FIXME: duti doesn't build on 10.12
# /usr/local/bin/duti ~/.duti

#
# Xcode
#

# Verbose codesign logging
#defaults write com.apple.dt.Xcode DVTCodesigningAllTheThingsLogLevel 3

# Show build times - http://stackoverflow.com/questions/1027923/how-to-enable-build-timing-in-xcode#answer-2801156
defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES

# Tweetbot
defaults write com.tapbots.TweetbotMac OpenURLsDirectly YES
