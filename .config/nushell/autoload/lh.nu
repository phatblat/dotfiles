# lh - List files with human-readable sizes
export def --wrapped lh [...args] {
    ^ls -lah ...$args
}
