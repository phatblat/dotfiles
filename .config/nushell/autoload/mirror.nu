# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Reset index and worktree to match the remote (hard reset to given treeish or HEAD)
export def mirror [...args: string] {
    ^git reset --hard ...$args
}
