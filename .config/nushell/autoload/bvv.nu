# bvv - Display git branch with details
export def bvv [...args] {
    ^git branch -vv ...$args
}
