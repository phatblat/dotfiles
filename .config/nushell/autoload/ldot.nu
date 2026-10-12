# ldot - List hidden files
export def --wrapped ldot [...args] {
    ^ls -ld .* ...$args
}
