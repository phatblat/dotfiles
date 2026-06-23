# Dependencies:
#   functions: none
#   builtins:  none
#   externals: docker

# Remove all unused local docker volumes, without confirmation
export def --wrapped dvp [...rest: string] {
    ^docker volume prune --force ...$rest
}
