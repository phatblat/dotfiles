# Dependencies:
#   functions: none
#   builtins:  none
#   externals: none

# Return true if running on Linux
export def is_linux [] {
    $nu.os-info.name == "linux"
}
