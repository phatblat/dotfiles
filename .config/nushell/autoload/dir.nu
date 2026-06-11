# Dependencies:
#   functions: none
#   builtins:  none
#   externals: docker

# Remove one or more docker images forcefully
export def --wrapped dir [...rest] {
    ^docker image rm --force ...$rest
}
