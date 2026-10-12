# lgfind - Search through git log for a specific pattern (pickaxe)
# Note: zsh uses `lg -S`, but `lg` is lazygit (no `-S` flag). The zsh
# source was broken; this nu port assumes the intent was `git log -S`.
export def lgfind [search_term?: string] {
    if ($search_term | is-empty) {
        error make { msg: "Usage: lgfind 'search term'" }
    }
    ^git log -S $search_term
}
