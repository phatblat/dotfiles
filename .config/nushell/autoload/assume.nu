# assume - Ignore changes to the given files
export def assume [...args] {
    ^git update-index --assume-unchanged ...$args
}
