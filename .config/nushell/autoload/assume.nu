# assume - Ignore changes to the given files
export def --wrapped assume [...args] {
    ^git update-index --assume-unchanged ...$args
}
