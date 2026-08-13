# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Edit the interactive-rebase todo file (~/.git/rebase-merge/git-rebase-todo)
export def todo [] {
    ^git rebase --edit-todo
}
