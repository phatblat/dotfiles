# Grep for gradle properties
export def gpgrep [...pattern: string] {
    gw properties | grep ...$pattern
}
