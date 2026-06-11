# Dependencies:
#   functions: none
#   builtins:  none
#   externals: docker

# Remove all unused docker networks, without confirmation
export def --wrapped dnp [...rest: string] {
    ^docker network prune --force ...$rest
}
