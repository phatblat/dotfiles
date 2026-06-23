# Dependencies:
#   functions: none
#   builtins:  none
#   externals: docker

# Remove unused docker images, without confirmation
export def --wrapped dip [...rest: string] {
    ^docker image prune --force ...$rest
}
