# checkout - Perform a git checkout
export def --wrapped checkout [...args] {
    ^git checkout ...$args
}
