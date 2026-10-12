# merge-base - Git merge-base wrapper
export def --wrapped merge-base [...args] {
    ^git merge-base ...$args
}
