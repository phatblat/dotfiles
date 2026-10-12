# mt - Short alias for git mergetool
export def --wrapped mt [...args] {
    ^git mergetool ...$args
}
