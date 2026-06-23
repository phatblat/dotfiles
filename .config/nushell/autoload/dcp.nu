# Dependencies:
#   functions: none
#   builtins:  none
#   externals: docker

# Remove all stopped docker containers without confirmation
export def dcp [] {
    ^docker container prune --force
}
