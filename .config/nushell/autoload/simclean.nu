# Dependencies:
#   functions: none
#   builtins:  none
#   externals: xcrun

# Deletes all unavailable Xcode simulators via xcrun simctl
export def simclean [] {
    ^xcrun simctl delete unavailable
}
