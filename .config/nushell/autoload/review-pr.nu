# Dependencies:
#   functions: none
#   builtins:  path join
#   externals: ~/scripts/review-pr.py

# review-pr - Review a GitHub PR with OMP and preserve interactive follow-up.
#
# Options (all optional, forwarded to review-pr.py):
#   --model <model>      OMP model (default: OMP profile's configured model)
#   --thinking <level>   OMP thinking level (default: high)
#   --profile <profile>  OMP profile (default: $OMP_PROFILE)
#
# Example: review-pr --model opus --thinking low --profile work widgets#123
export def --wrapped 'review-pr' [...rest: string] {
    ^($nu.home-dir | path join "scripts" "review-pr.py") ...$rest
}
