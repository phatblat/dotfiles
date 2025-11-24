export def ri [count: int = 10] {
    ^git rebase --interactive $"HEAD~($count)"
}
