# Dependencies:
#   functions: rv
#   builtins:  none
#   externals: git

# Rename the 'origin' remote to 'upstream' and display remotes
export def upstreamify [] {
    ^git remote rename origin upstream
    rv
}
