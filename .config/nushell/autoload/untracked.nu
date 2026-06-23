# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# List untracked files in the current git repo (not in .gitignore)
export def --wrapped untracked [...rest] {
    ^git ls-files --others --exclude-standard ...$rest
}
