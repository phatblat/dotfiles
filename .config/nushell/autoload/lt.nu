# lt - Long list, sorted by date, show type, human readable
export def --wrapped lt [...args] {
    ^ls -otFh ...$args
}
