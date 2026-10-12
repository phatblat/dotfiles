# dcw - Diff the git staging area using word diff
export def --wrapped dcw [...args] {
    ^git diff --cached --word-diff ...$args
}
