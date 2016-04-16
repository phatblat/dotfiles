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
alias op='cd ~/dev/ios/Octopad'
alias og='cd ~/dev/libgit2/objective-git'
alias ebw='cd ~/dev/ios/EBW'
alias fk='cd ~/dev/ios/pods/FitnessKit'
alias itwire='cd ~/dev/bluemix/ITWire'
alias flagship='cd ~/dev/ios/flagship/KPFlagship'

# Blog main dir
alias rl='cd ~/dev/www/reflog/www'
