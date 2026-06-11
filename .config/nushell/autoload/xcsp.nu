# Dependencies:
#   functions: none
#   builtins:  none
#   externals: xcode-select

# Prints the path of the currently selected Xcode developer directory
export def --wrapped xcsp [...rest] {
    ^xcode-select --print-path ...$rest
}
