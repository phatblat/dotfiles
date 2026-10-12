# bvv - Display git branch with details
export def --wrapped bvv [...args] {
    ^git branch -vv ...$args
}
