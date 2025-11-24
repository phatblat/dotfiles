# Short alias for open
export def o [path?: string] {
    if ($path == null) {
        ^open .
    } else {
        # -t causes the given path to be opened with the default app
        ^open -t $path
    }
}
