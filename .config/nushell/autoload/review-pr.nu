# Dependencies:
#   functions: none
#   builtins:  path join
#   externals: ~/scripts/review-pr.py

# Review a GetDitto GitHub PR with Codex and filter existing threads
export def --wrapped 'review-pr' [...rest: string] {
    ^($nu.home-dir | path join "scripts" "review-pr.py") ...$rest
}
