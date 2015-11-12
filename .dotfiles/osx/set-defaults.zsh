# https://raw.github.com/holman/dotfiles/master/osx/set-defaults.sh
# -----
# Sets reasonable OS X defaults.
#
# Or, in other words, set shit how I like in OS X.
#
# The original idea (and a couple settings) were grabbed from:
#   https://github.com/mathiasbynens/dotfiles/blob/master/.osx
#
# Run ./set-defaults.sh and you'll be good to go.

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

# Hide Safari's bookmark bar.
defaults write com.apple.Safari ShowFavoritesBar -bool false

# Set up Safari for development.
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

#  - http://furbo.org/2014/09/03/xcode-vs-gatekeeper/
alias ungate='xattr -d com.apple.quarantine '

# QuickLook text selection
defaults write com.apple.finder QLEnableTextSelection -bool TRUE

# Configure the default handler for public.plain-text
defaults write com.apple.LaunchServices LSHandlers -array-add \
  '{LSHandlerContentType=public.plain-text;LSHandlerRoleAll=com.github.atom;}'

#
# Xcode
#

# Verbose codesign logging
#defaults write com.apple.dt.Xcode DVTCodesigningAllTheThingsLogLevel 3

# Show build times - http://stackoverflow.com/questions/1027923/how-to-enable-build-timing-in-xcode#answer-2801156
defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES
