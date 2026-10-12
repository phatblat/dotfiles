# lggrep - Grep through git log for a regex pattern
# Note: zsh uses `lg -G`, but `lg` is lazygit (no `-G` flag). The zsh
# source was broken; this nu port assumes the intent was `git log -G`.
export def lggrep [pattern: string] {
    if ($pattern | is-empty) {
        error make { msg: "Usage: lggrep '.*'" }
    }
    ^git log -G $pattern
}
