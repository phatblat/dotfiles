# Dependencies:
#   functions: review-pr
#   builtins:  none
#   externals: none

# rpr - Alias for review-pr.
#
# Options (all optional, forwarded to review-pr.py):
#   --model <model>      OMP model (default: OMP profile's configured model)
#   --thinking <level>   OMP thinking level (default: high)
#   --profile <profile>  OMP profile (default: $OMP_PROFILE)
#
# Example: rpr --model opus --thinking low --profile work widgets#123
export def --wrapped rpr [...rest: string] {
    review-pr ...$rest
}
