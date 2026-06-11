# Dependencies:
#   functions: none
#   builtins:  none
#   externals: sudo xcode-select

# Select a different version of Xcode via xcode-select --switch
export def --wrapped xcss [...rest] {
    ^sudo xcode-select --switch ...$rest
}
