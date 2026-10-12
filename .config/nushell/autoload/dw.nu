# dw - Git diff with word diff
export def dw [...args] {
    ^git diff --word-diff ...$args
}
