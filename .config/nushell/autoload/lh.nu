# lh - List files with human-readable sizes
export def lh [...args] {
    ^ll -h ...$args
}
