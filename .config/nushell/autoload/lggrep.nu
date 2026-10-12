# lggrep - Grep through lightweight log `lg` for a regex pattern
export def lggrep [pattern: string] {
    if ($pattern | is-empty) {
        error make { msg: "Usage: lggrep '.*'" }
    }
    lg -G $pattern
}
