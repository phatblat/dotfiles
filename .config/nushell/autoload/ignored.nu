# Show files ignored by git
export def ignored [...args: string] {
    ^git status --ignored --porcelain ...$args
}
