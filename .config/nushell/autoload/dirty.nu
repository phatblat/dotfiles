# dirty - Show repo dirty files
export def dirty [] {
    ^git clean -xd --force --dry-run
}
