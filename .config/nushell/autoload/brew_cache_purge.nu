# brew_cache_purge - Purges the Homebrew cache
export def brew_cache_purge [] {
    let cache = (^brew --cache | str trim)
    ^rm -rf $cache
}
