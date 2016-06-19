#-------------------------------------------------------------------------------
#
# shell/dirs.zsh
# Quick dir navigation commands
#
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
#
# Directory Variables
#
#-------------------------------------------------------------------------------

ICLOUD_HOME="$HOME/Library/Mobile Documents"
ICLOUD_DRIVE="${ICLOUD_HOME}/com~apple~CloudDocs"


#-------------------------------------------------------------------------------
#
# Directory Navigation (cd)
#
#-------------------------------------------------------------------------------

alias icloud="cd $ICLOUD_HOME"
alias iclouddrive="cd $ICLOUD_DRIVE"

# Common Xcode project folders
alias radars='cd ~/dev/radars'
alias ol='cd ~/dev/ios/pods/Outlets'
alias op='cd ~/dev/ios/Octopad'
alias og='cd ~/dev/libgit2/objective-git'
alias quick='cd ~/dev/ios/pods/Quick'
alias nimble='cd ~/dev/ios/pods/Nimble'
alias sg='cd ~/dev/xcode/SwiftGen'

# KP Projects
alias ebw='cd ~/dev/ios/EBW'
alias fk='cd ~/dev/ios/pods/FitnessKit'
alias itwire='cd ~/dev/bluemix/ITWire'
alias flagship='cd ~/dev/ios/flagship'
alias realm='cd ~/dev/realm'

# reflog, markdown
alias rl='cd ~/dev/www/reflog/www'
alias asv='cd ~/dev/markdown/AppleSoftwareVersions'
