# Dependencies:
#   functions: none
#   builtins:  none
#   externals: tmutil

# List local Time Machine snapshots
export def tmsnapshots [] {
    ^tmutil listlocalsnapshots /
}
