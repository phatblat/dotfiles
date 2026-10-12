# theirs - Checkout theirs for unmerged paths
export def --wrapped theirs [...args] {
    ^git checkout --theirs ...$args
    ^git add ...$args
}
