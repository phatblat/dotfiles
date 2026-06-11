# Dependencies:
#   functions: none
#   builtins:  none
#   externals: none

# Return true if running on macOS
export def is_mac [] {
    $nu.os-info.name == "macos"
}
