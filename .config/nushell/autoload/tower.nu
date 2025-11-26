# Open the current repo in Tower
export def tower [...args] {
    gittower (git rev-parse --show-toplevel | complete | get stdout | str trim) ...$args
}
