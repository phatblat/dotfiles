# ldot - List hidden files
export def ldot [...args] {
    ^ls -ld .* ...$args
}
