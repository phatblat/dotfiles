# Interactive rebase for the last few commits
export def r [count?: int = 10] {
    # Note: toggle_wait is a fish-specific function
    # In nushell, we can just run the command directly
    ^git rebase --interactive $"HEAD~($count)"
}
