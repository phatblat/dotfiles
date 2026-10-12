# dcw - Diff the git staging area using word diff
export def dcw [...args] {
    ^git diff --cached --word-diff ...$args
}
