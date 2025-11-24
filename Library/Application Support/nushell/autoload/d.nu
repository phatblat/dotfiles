# Git diff with custom options
export def d [...args] {
    ^git diff --unified=1 --no-prefix ...$args
}
