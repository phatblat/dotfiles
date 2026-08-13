# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Checkout paths from the index taking "ours" for unmerged paths, then stage them
export def ours [...paths: string] {
    ^git checkout --ours ...$paths
    ^git add ...$paths
}
