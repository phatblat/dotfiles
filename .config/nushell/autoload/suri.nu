# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Initialize and update git submodules recursively, forwarding extra args
export def --wrapped suri [...rest] {
    ^git submodule update --recursive --init ...$rest
}
