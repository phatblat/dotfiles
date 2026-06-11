# Dependencies:
#   functions: dcp dvp dip dnp
#   builtins:  none
#   externals: none

# Docker deep clean (prune containers, volumes, images, networks)
export def ddc [] {
    dcp
    dvp
    dip
    dnp
}
