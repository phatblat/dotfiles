# theirs - Checkout theirs for unmerged paths
export def theirs [...args] {
    ^git checkout --theirs ...$args
    ^git add ...$args
}
