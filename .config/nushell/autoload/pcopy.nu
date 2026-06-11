# Dependencies:
#   functions: none
#   builtins:  pwd str trim
#   externals: pbcopy

# Copy the current working directory path to the macOS clipboard
export def pcopy [] {
    pwd | str trim | ^pbcopy
}
