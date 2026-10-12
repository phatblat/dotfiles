# lt - Long list, sorted by date, show type, human readable
export def lt [...args] {
    ^ls -otFh ...$args
}
