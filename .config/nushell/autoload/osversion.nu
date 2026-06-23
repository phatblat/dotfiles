# Dependencies:
#   functions: none
#   builtins:  none
#   externals: sw_vers

# Print the macOS product version number
export def osversion [] {
    ^sw_vers -productVersion
}
