# tracking - Display tracking information for the current branch
export def tracking [...args] {
    ^git rev-parse --abbrev-ref --symbolic-full-name @{u} ...$args
}
