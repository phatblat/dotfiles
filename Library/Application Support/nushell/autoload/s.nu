# Display abbreviated git status
export def s [...args] {
    ^git status -sb ...$args
}
