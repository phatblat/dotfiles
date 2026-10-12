# ls-files - Git ls-files
export def --wrapped ls-files [...args] {
    ^git ls-files ...$args
}
