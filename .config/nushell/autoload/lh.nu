# lh - List files with human-readable sizes
export def --wrapped lh [...args] {
    ll -h ...$args
}
