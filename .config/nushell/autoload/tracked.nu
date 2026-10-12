# tracked - Displays files tracked in the current git repo
export def --wrapped tracked [...args] {
    ^git ls-tree -r --name-only HEAD ...$args
}
