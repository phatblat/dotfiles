# dw - Git diff with word diff
export def --wrapped dw [...args] {
    ^git diff --word-diff ...$args
}
