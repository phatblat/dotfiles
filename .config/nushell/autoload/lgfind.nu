# lgfind - Search through lightweight log `lg` for a specific pattern
export def lgfind [search_term?: string] {
    if ($search_term | is-empty) {
        error make { msg: "Usage: lgfind 'search term'" }
    }
    ^lg -S $search_term
}
