# log1 - Show last git commit with full details
export def --wrapped log1 [...args] {
    ^git log -1 --pretty=fuller ...$args
}
