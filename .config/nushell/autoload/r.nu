# Interactive rebase for the last few commits
export def r [count?: int = 10] {
    # Nushell runs the rebase command directly without a shell-specific helper.
    # In nushell, we can just run the command directly
    ^git rebase --interactive $"HEAD~($count)"
}
