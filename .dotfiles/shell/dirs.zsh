#-------------------------------------------------------------------------------
#
# shell/dirs.zsh
# Quick dir navigation commands
#
#-------------------------------------------------------------------------------

lj info 'shell/dirs.zsh'


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
hash -d radars="${HOME}/dev/radars"
hash -d ol="${HOME}/dev/ios/pods/Outlets"
hash -d op="${HOME}/dev/ios/Octopad"
hash -d og="${HOME}/dev/libgit2/objective-git"
hash -d quick="${HOME}/dev/ios/pods/Quick"
hash -d nimble="${HOME}/dev/ios/pods/Nimble"
hash -d clv="${HOME}/dev/ios/CLVisitExplorer"
hash -d sg="${HOME}/dev/xcode/SwiftGen"

# KP Projects
hash -d ebw="${HOME}/dev/ios/EBW"
hash -d fk="${HOME}/dev/ios/pods/FitnessKit"
hash -d itwire="${HOME}/dev/bluemix/ITWire"
hash -d flagship="${HOME}/dev/ios/flagship"
hash -d realm="${HOME}/dev/realm"
hash -d pods="${HOME}/dev/ios/pods"
hash -d pipeline="${HOME}/dev/gradle/PipelineGradlePlugin"

# reflog, markdown
hash -d rl="${HOME}/dev/www/reflog/www"
hash -d asv="${HOME}/dev/markdown/AppleSoftwareVersions"
